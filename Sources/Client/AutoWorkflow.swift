import AITools
import Foundation
import GeminiSDK
import SwiftAIAgent

struct AutoWorkflow {
    enum Example {
        case summariseAIHistory
        case summariseMeetingWithImage
        case latestNewsInSydney
        case ceativeWriting
        case saveSearchResultToGoogleSheets
        case tripPlanning
        case getGitHubRepoTags
        case addImageAndTextToSlides

        var goal: String {
            switch self {
            case .summariseAIHistory:
                """
                - Summarise AI history
                - gemerate an image for the article
                - save it in a markdow file 
                """
            case .summariseMeetingWithImage:
                """
                - Summarise the meeting Trump and Putin have had in Alaska on 15 August 2025.
                - accompanied by a political cartoon.
                - Save it in a markdown file.
                """
            case .latestNewsInSydney:
                """
                - Latest News in Sydney (Past 24 Hours)
                - Save it in a markdown file.
                """
            case .ceativeWriting:
                """
                - write an emotional story filled with dramatic moments, 
                - exploring the relationship between a pet and its owner.
                - save it in a markdown file
                """
            case .saveSearchResultToGoogleSheets:
                """
                - search top 10 web pages that are about AI Coding practice
                - save the title and url of the webpage to the google sheet.
                """
            case .addImageAndTextToSlides:
                """
                - Creates a slide in the Slides file
                - add text `Text added by AI` to the slide
                - add image https://deepresearch.timwang.au/results/F3275E05-7864-4115-AA82-060A393D437F.png to the slide
                """
            case .tripPlanning:
                """
                - Organize a 10-day journey to Japan in December for three people, aiming for a moderate budget.
                - save it in a markdown file
                """
            case .getGitHubRepoTags:
                """
                - get all the tags of this repo https://github.com/ShenghaiWang/SwiftAIAgent.git.
                - save it in a markdown file
                """
            }
        }
    }
    let model: AIAgentModel
    let managerAgent: AIAgent
    let goalManager: GoalManager

    static func run(goal: AutoWorkflow.Example) async throws {
        let model = GeminiSDK(model: geminiModel, apiKey: geminiAPIKey)
        let autoWorkflow = try await AutoWorkflow(model: model, goal: goal.goal)
        try await autoWorkflow.runInternal()
    }

    init(model: AIAgentModel, goal: String) async throws {
        self.model = model
        self.managerAgent = try await AIAgent(title: "Manager", model: model)
        let baseFolder = "."
        let fileIO = FileIO(baseFolder: baseFolder)
        let googleServiceAccount =
            ProcessInfo.processInfo.environment["Google_Service_Account"] ?? ""
        let googleSheetId = ProcessInfo.processInfo.environment["Google_Sheet_ID"] ?? ""
        let googlePresentationId =
            ProcessInfo.processInfo.environment["Google_Presentation_ID"] ?? ""
        let cx = ProcessInfo.processInfo.environment["cx"] ?? ""
        let key = ProcessInfo.processInfo.environment["key"] ?? ""
        let gitHubURL = URL(string: "https://api.githubcopilot.com/mcp/")!
        let gitHubToken = ProcessInfo.processInfo.environment["GitHubToken"] ?? ""
        let googleSheetsTool = try GoogleSheets(
            serviceAccount: googleServiceAccount, sheetId: googleSheetId)
        let googleSlidesTool = try GoogleSlides(
            serviceAccount: googleServiceAccount, presentationId: googlePresentationId)
        self.goalManager = GoalManager(
            goal: goal,
            managerAgent: managerAgent,
            models: [model],
            tools: [
                fileIO,
                GoogleSearch(cx: cx, key: key),
                Fetch(),
                GeminiImage(apiKey: geminiAPIKey, baseFolder: baseFolder),
                DateTime(),
                googleSheetsTool,
                googleSlidesTool,
            ],
            mcpServers: [.http(url: gitHubURL, token: gitHubToken)])
    }

    func runInternal() async throws {
        do {
            let result = try await goalManager.run(noFutherClarification: true)
            print(result)
        } catch {
            if case let GoalManager.Error.needClarification(questions) = error {
                print(
                    questions
                        .enumerated()
                        .map { "\($0 + 1): \($1)" }
                        .joined(separator: "\n"))
                let clarifications = readLine()
                await goalManager.set(clarifications: [clarifications ?? ""])
                try await runInternal()
            } else {
                print(error)
            }
        }
    }
}
