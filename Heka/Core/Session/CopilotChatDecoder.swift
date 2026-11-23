import Foundation

struct CopilotChatDecoder: ChatJournalDecoder {
    private var log = ChatMessageLog()
    private var model = CopilotModelState()
    private var taskCompleteCalls: Set<String> = []
    private var turnReplies: [String: String] = [:]
    private var turnSummaries: [String: String] = [:]

    var messages: [SessionMessage] { log.messages }

    var options: AgentOptionsReport {
        model == CopilotModelState() ? AgentOptionsReport() : AgentOptionsReport(copilot: model)
    }

    mutating func trim() { log.trim() }

    mutating func consume(_ line: Data, offset: UInt64) {
        guard let record = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let data = record["data"] as? [String: Any] else { return }
        let id = record["id"] as? String ?? "line:\(offset)"
        switch record["type"] as? String {
        case "session.start", "session.resume":
            if let reported = CopilotModel(reported: data["selectedModel"] as? String) { select(reported) }
        case "session.model_change":
            guard let reported = CopilotModel(reported: data["newModel"] as? String) else { return }
            let isAutomatic = data["source"] as? String == "automatic"
            if isAutomatic, model.selected?.isAutomatic == true {
                model.running = reported
            } else if isAutomatic, model.selected == nil, data["cause"] as? String != "initial_resolution" {
                model.running = reported
            } else {
                select(reported)
            }
        case "session.auto_mode_resolved":
            model.running = CopilotModel(reported: data["chosenModel"] as? String) ?? model.running
        case "user.message":
            startTurn()
            log.addText(ChatMessageLog.text(data["content"]), id: id, kind: .input)
        case "assistant.message":
            if model.running == nil { model.running = CopilotModel(reported: data["model"] as? String) }
            addReply(ChatMessageLog.text(data["content"]), id: data["messageId"] as? String ?? id)
            for request in data["toolRequests"] as? [[String: Any]] ?? [] {
                guard let call = request["toolCallId"] as? String else { continue }
                startTool(call, name: request["name"] as? String,
                          arguments: request["arguments"] as? [String: Any] ?? [:])
            }
        case "assistant.message_delta":
            guard let messageID = data["messageId"] as? String else { return }
            turnReplies[messageID] = ""
            log.addText(log.text(of: messageID) + (data["deltaContent"] as? String ?? ""), id: messageID, kind: .assistant)
        case "tool.execution_start":
            guard let call = data["toolCallId"] as? String else { return }
            startTool(call, name: data["toolName"] as? String,
                      arguments: data["arguments"] as? [String: Any] ?? [:])
        case "tool.execution_complete":
            guard let call = data["toolCallId"] as? String else { return }
            guard !taskCompleteCalls.contains(call) else { return startTurn() }
            let result = data["result"] as? [String: Any] ?? [:]
            let output = ChatMessageLog.text(result["detailedContent"] ?? result["content"])
            let error = (data["error"] as? [String: Any])?["message"] as? String
            log.finishTool(call, output: output.isEmpty ? error ?? "" : output, failed: data["success"] as? Bool == false)
        default: return
        }
    }

    mutating func consumeOversized(_ head: Data) {
        guard String(decoding: head, as: UTF8.self).contains("\"tool.execution_complete\"") else { return }
        log.finishOversizedTools(in: head, key: "toolCallId", excluding: taskCompleteCalls)
    }

    private mutating func select(_ reported: CopilotModel) {
        model = CopilotModelState(choosing: reported)
    }

    private mutating func startTool(_ call: String, name: String?, arguments: [String: Any]) {
        if name == "task_complete" || taskCompleteCalls.contains(call) {
            taskCompleteCalls.insert(call)
            addSummary(ChatMessageLog.text(arguments["summary"]), call: call)
        } else {
            log.startTool(call, name: name ?? String(localized: "Tool"), detail: ChatMessageLog.summary(of: arguments))
        }
    }

    private mutating func startTurn() {
        turnReplies = [:]
        turnSummaries = [:]
    }

    private mutating func addReply(_ text: String, id: String) {
        let key = ChatMessageLog.visibleText(text)
        guard !key.isEmpty else { return }
        turnReplies[id] = key
        log.addText(text, id: id, kind: .assistant)
        for (call, summary) in turnSummaries where summary == key {
            turnSummaries[call] = nil
            log.remove("tool:\(call)")
        }
    }

    private mutating func addSummary(_ text: String, call: String) {
        let key = ChatMessageLog.visibleText(text)
        guard !key.isEmpty, !turnReplyKeys().contains(key) else { return }
        turnSummaries[call] = key
        log.addText(text, id: "tool:\(call)", kind: .assistant)
    }

    private mutating func turnReplyKeys() -> Set<String> {
        for (id, key) in turnReplies where key.isEmpty {
            turnReplies[id] = ChatMessageLog.visibleText(log.text(of: id))
        }
        return Set(turnReplies.values)
    }
}
