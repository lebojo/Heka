import Foundation
import SQLite3

extension ChatJournalTests {
    static func execute(_ sql: String, in database: OpaquePointer?) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw NSError(domain: String(cString: sqlite3_errmsg(database)), code: 1)
        }
    }

    static func quoted(_ text: String) -> String { "'" + text.replacingOccurrences(of: "'", with: "''") + "'" }

    @MainActor static func agentChatSupport() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("heka-chat-support-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("state_5.sqlite")
        var database: OpaquePointer?
        try require(sqlite3_open(url.path, &database) == SQLITE_OK, "Create fixture database")
        defer { sqlite3_close(database) }
        try execute("PRAGMA journal_mode=WAL; PRAGMA wal_autocheckpoint=0", in: database)
        try execute("CREATE TABLE threads(id TEXT, rollout_path TEXT, cwd TEXT, created_at INTEGER, archived INTEGER)", in: database)
        let rollout = root.appendingPathComponent("rollout.jsonl")
        try Data().write(to: rollout)
        let start = Date(timeIntervalSince1970: 1000)
        try execute("INSERT INTO threads VALUES('current', \(quoted(rollout.path)), '/project', 1001, 0)", in: database)
        try execute("INSERT INTO threads VALUES('old', \(quoted(rollout.path)), '/project', 100, 0)", in: database)
        try execute("INSERT INTO threads VALUES('other', \(quoted(rollout.path)), '/elsewhere', 1001, 0)", in: database)
        let match = AgentSessionLocator.codex(home: root, directory: "/project", startedAt: start, sessionID: nil)
        try require(match?.id == "current" && match?.path == rollout.path, "Codex attaches a closed rollout using the WAL-backed thread index")
        try execute("INSERT INTO threads VALUES('concurrent', \(quoted(rollout.path)), '/project', 1002, 0)", in: database)
        try require(AgentSessionLocator.codex(home: root, directory: "/project", startedAt: start, sessionID: nil) == nil,
                    "Ambiguous simultaneous sessions must not show another terminal's conversation")
        try require(AgentSessionLocator.codex(home: root, directory: "/project", startedAt: start, sessionID: "old")?.id == "old",
                    "Explicit resumes locate sessions older than the process")
        try require(AgentSessionLocator.explicitSession(in: ["codex", "resume", "--last"], agent: .codex) == nil,
                    "Resume flags are not session IDs")
        try require(AgentSessionLocator.explicitSession(in: ["opencode", "--session=ses_old"], agent: .openCode) == "ses_old",
                    "OpenCode explicit session flag")
        print("PASS Codex session association without open journal descriptors, resumes and ambiguity")

        try execute("""
            CREATE TABLE session(id TEXT PRIMARY KEY, directory TEXT, time_created INTEGER, parent_id TEXT, time_archived INTEGER);
            CREATE TABLE message(id TEXT PRIMARY KEY, session_id TEXT, time_created INTEGER, data TEXT);
            CREATE TABLE part(id TEXT PRIMARY KEY, session_id TEXT, message_id TEXT, data TEXT);
            INSERT INTO session VALUES('ses_old', '/project', 1001000, NULL, NULL);
            INSERT INTO message VALUES('m1', 'ses_old', 1, '{"role":"user"}');
            INSERT INTO message VALUES('m2', 'ses_old', 2, '{"role":"assistant"}');
            INSERT INTO part VALUES('p1', 'ses_old', 'm1', '{"type":"text","text":"Bonjour"}');
            INSERT INTO part VALUES('p2', 'ses_old', 'm1', '{"type":"text","text":"PRIVATE","synthetic":true}');
            INSERT INTO part VALUES('p3', 'ses_old', 'm2', '{"type":"reasoning","text":"PRIVATE"}');
            INSERT INTO part VALUES('p4', 'ses_old', 'm2', '{"type":"text","text":"**Bonjour**"}');
            INSERT INTO part VALUES('p5', 'ses_old', 'm2', '{"type":"tool","tool":"bash","state":{"status":"running","input":{"command":"swift test"}}}');
            INSERT INTO message VALUES('foreign', 'other_session', 3, '{"role":"assistant"}');
            INSERT INTO part VALUES('p6', 'other_session', 'foreign', '{"type":"text","text":"OTHER SESSION"}');
            """, in: database)
        let oldReader = OpenCodeChatReader(sessionID: "ses_old")
        let old = await oldReader.read(url)
        try require(old.map(\.kind) == [.input, .assistant, .tool] && old[1].text == "**Bonjour**", "OpenCode legacy roles and Markdown preserved")
        try require(old[2].detail == "swift test" && old[2].toolState == .running, "OpenCode running command preserved")
        try require(AgentSessionLocator.openCode(database: url, directory: "/project", startedAt: start, sessionID: nil)?.id == "ses_old",
                    "OpenCode associates a new root session")
        try execute("UPDATE part SET data = '{\"type\":\"tool\",\"tool\":\"bash\",\"state\":{\"status\":\"completed\",\"input\":{\"command\":\"swift test\"},\"output\":\"PASS\"}}' WHERE id='p5'", in: database)
        let completed = await oldReader.read(url)
        try require(completed.last?.text == "PASS" && completed.last?.detail == "swift test" && completed.last?.id == old.last?.id,
                    "OpenCode in-place tool updates keep stable identities and commands")
        let unchanged = await oldReader.read(url)
        try require(unchanged == completed, "An unchanged database keeps its snapshot")

        try execute("""
            CREATE TABLE session_v2(id TEXT PRIMARY KEY, directory TEXT, time_created INTEGER, parent_id TEXT, time_archived INTEGER);
            CREATE TABLE session_message(id TEXT PRIMARY KEY, session_id TEXT, type TEXT, seq INTEGER, data TEXT);
            CREATE TABLE session_part(message_id TEXT, session_id TEXT, ordinal INTEGER, data TEXT);
            INSERT INTO session_v2 VALUES('ses_new', '/modern', 1001000, NULL, NULL);
            INSERT INTO session_message VALUES('u', 'ses_new', 'user', 1, '{"text":"Corrige"}');
            INSERT INTO session_message VALUES('a', 'ses_new', 'assistant', 2, '{}');
            INSERT INTO session_message VALUES('s', 'ses_new', 'system', 3, '{"text":"PRIVATE"}');
            INSERT INTO session_part VALUES('a', 'ses_new', 0, '{"type":"text","text":"Voici"}');
            INSERT INTO session_part VALUES('a', 'ses_new', 1, '{"type":"tool","name":"bash","state":{"status":"error","input":{"command":"false"},"error":{"message":"Failed"}}}');
            INSERT INTO session_part VALUES('a', 'ses_new', 2, '{"type":"tool","name":"read","state":{"status":"completed","input":{"path":"main.swift"},"content":[{"type":"text","text":"let x = 1"}]}}');
            """, in: database)
        let modern = await OpenCodeChatReader(sessionID: "ses_new").read(url)
        try require(modern.map(\.kind) == [.input, .assistant, .tool, .tool], "OpenCode v2 reads user text and ordered assistant parts")
        try require(modern[2].toolState == .failed && modern[2].text == "Failed" && modern[3].text == "let x = 1",
                    "OpenCode v2 tool errors and content arrays")
        let oldAfterMigration = await oldReader.read(url)
        try require(oldAfterMigration == completed, "An existing v2 table must not hide an unmigrated legacy session")

        let transcript = SessionTranscript()
        let monitor = AgentJournalMonitor(transcript: transcript)
        let journal = AgentJournal(source: .openCode, url: url, sessionID: "ses_new")
        monitor.attach(journal)
        try await eventually("OpenCode monitor reads v2") { transcript.messages.count == 4 }
        try execute("UPDATE session_part SET data = '{\"type\":\"text\",\"text\":\"Live WAL update\"}' WHERE message_id='a' AND ordinal=0", in: database)
        try await eventually("OpenCode follows writes to the WAL") { transcript.messages[1].text == "Live WAL update" }
        monitor.suspend()
        try execute("UPDATE session_part SET data = '{\"type\":\"text\",\"text\":\"While suspended\"}' WHERE message_id='a' AND ordinal=0", in: database)
        monitor.attach(journal)
        try await eventually("OpenCode resumes watching") { transcript.messages[1].text == "While suspended" }
        monitor.attach(AgentJournal(source: .openCode, url: url, sessionID: "ses_old"))
        try await eventually("Changing OpenCode sessions in the same database reloads the conversation") { transcript.messages.first?.text == "Bonjour" }
        monitor.attach(nil)
        try require(transcript.source == .terminal, "OpenCode detaches")
        print("PASS OpenCode legacy/v2 transcripts, hidden context, tool state, WAL updates and session switching")

        var copilot = CopilotChatDecoder()
        for (index, event) in [
            try line(["type": "assistant.message_delta", "data": ["messageId": "a", "deltaContent": "Bon"]]),
            try line(["type": "assistant.message_delta", "data": ["messageId": "a", "deltaContent": "jour"]]),
            try line(["type": "assistant.message", "data": ["messageId": "a", "content": "Bonjour", "toolRequests": [["toolCallId": "t", "name": "bash", "arguments": ["command": "git diff"]]]]]),
            try line(["type": "tool.execution_complete", "data": ["toolCallId": "t", "success": true, "result": ["content": "Modified", "detailedContent": "+ fixed"]]])
        ].enumerated() { copilot.consume(event, offset: UInt64(index)) }
        try require(copilot.messages.count == 2 && copilot.messages[0].text == "Bonjour", "Copilot streaming is replaced by the final message without duplication")
        try require(copilot.messages[1].text == "+ fixed" && copilot.messages[1].detail == "git diff", "Copilot requests retain commands and detailed results")
        let encoded = try JSONEncoder().encode(copilot.messages)
        let decoded = try JSONDecoder().decode([SessionMessage].self, from: encoded)
        try require(decoded == copilot.messages, "Tool command details survive remote encoding")
        var changedDetail = copilot.messages
        changedDetail[1].detail = "git diff --check"
        let detailDelta = SessionTranscriptDelta(previous: copilot.messages, current: changedDetail)
        try require(detailDelta.append == nil && detailDelta.messages.last?.detail == "git diff --check",
                    "A command change is sent as metadata, not a text-only delta")
        var boundedTools = (0..<10).map { SessionMessage(id: "t\($0)", kind: .tool, text: "Done", detail: String(repeating: "x", count: 65_536)) }
        boundedTools.trimHistory(keepingAtLeast: 1)
        try require(boundedTools.count == 3, "Tool commands count toward the remote history byte budget")
        print("PASS Copilot streaming, tool requests, detailed results and remote command metadata")
        try copilotTaskComplete()

        let code = "let café = \"👋 // not a comment\" // comment\nlet number = 42"
        let tokens = SessionCodeTokens.parse(code, language: "swift")
        try require(tokens.map(\.kind) == [.keyword, .string, .comment, .keyword, .number], "Code highlighting respects strings, comments and Unicode")
        try require(tokens.allSatisfy { Range($0.range, in: code) != nil }, "Highlight ranges respect Unicode boundaries")
        try require(SessionCodeTokens.parse("plain text", language: "unknown").isEmpty, "Unknown languages remain readable")
        try require(SessionCodeTokens.parse("- old\n+ new", language: "diff").map(\.kind) == [.deletion, .addition], "Diff additions and deletions highlighted")
        print("PASS syntax highlighting tokens and Unicode ranges")
    }

    static func copilotTaskComplete() throws {
        let summary = "**Terminé 👋**\n\n- Le correctif est prêt.\n\n```swift\nlet fixed = true\n```"
        let request = try line(["type": "assistant.message", "id": "request", "data": ["messageId": "answer", "content": "",
            "toolRequests": [["toolCallId": "done", "name": "task_complete", "arguments": ["summary": summary]]]]])
        let start = try line(["type": "tool.execution_start", "data": ["toolCallId": "done", "toolName": "task_complete",
            "arguments": ["summary": summary]]])
        let complete = try line(["type": "tool.execution_complete", "data": ["toolCallId": "done", "success": true,
            "result": ["content": "Task completed", "detailedContent": "Internal acknowledgement"]]])
        let expected = SessionMessage(id: "tool:done", kind: .assistant, text: summary)

        // A persisted journal can include both declarations, or start after the request.
        for declarations in [[request, start], [request], [start]] {
            var decoder = CopilotChatDecoder()
            for (offset, event) in declarations.enumerated() { decoder.consume(event, offset: UInt64(offset)) }
            try require(decoder.messages == [expected], "task_complete exposes one Markdown assistant reply before completion")
            decoder.consume(complete, offset: 10)
            decoder.consume(complete, offset: 10)
            decoder.consume(try line(["type": "session.task_complete", "data": ["summary": summary]]), offset: 11)
            try require(decoder.messages == [expected], "Completion acknowledgements never replace, duplicate or reclassify the reply")
            decoder.consumeOversized(Data(#"{"type":"tool.execution_complete","data":{"toolCallId":"done","result":{"content":""#.utf8))
            try require(decoder.messages == [expected], "Oversized completion acknowledgements preserve the reply and its metadata")
            let encoded = try JSONEncoder().encode(decoder.messages)
            let decoded = try JSONDecoder().decode([SessionMessage].self, from: encoded)
            try require(decoded == [expected], "task_complete stays an assistant reply over the remote protocol")
        }

        var decoder = CopilotChatDecoder()
        decoder.consume(request, offset: 0)
        decoder.consume(try line(["type": "tool.execution_start", "data": ["toolCallId": "done", "toolName": "task_complete"]]), offset: 1)
        try require(decoder.messages == [expected], "A start event without arguments keeps the request's summary")
        decoder.consume(complete, offset: 2)
        decoder.consume(try line(["type": "tool.execution_start", "data": ["toolCallId": "bash", "toolName": "bash",
            "arguments": ["command": "swift test"]]]), offset: 3)
        decoder.consume(try line(["type": "tool.execution_complete", "data": ["toolCallId": "bash", "success": false,
            "error": ["message": "1 test failed"]]]), offset: 4)
        try require(decoder.messages.map(\.kind) == [.assistant, .tool] && decoder.messages[1].title == "bash"
                    && decoder.messages[1].toolState == .failed && decoder.messages[1].text == "1 test failed",
                    "Ordinary bash calls still display their tool state and output")

        for (index, arguments) in [[:], ["summary": " \n"]].enumerated() {
            decoder.consume(try line(["type": "tool.execution_start", "data": ["toolCallId": "empty-\(index)",
                "toolName": "task_complete", "arguments": arguments]]), offset: 5)
            decoder.consume(try line(["type": "tool.execution_complete", "data": ["toolCallId": "empty-\(index)", "success": true,
                "result": ["content": "Task completed"]]]), offset: 6)
        }
        try require(decoder.messages.count == 2, "Absent or blank summaries do not create empty replies or acknowledgement tool rows")
        print("PASS Copilot task_complete assistant replies, lifecycle deduplication, oversized results and remote encoding")
    }
}
