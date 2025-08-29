import AITools
import Foundation
import GeminiSDK
import SwiftAIAgent

struct AutoWorkflow {
    enum Example {
        /// Generate scientific article
        case summariseAIHistory
        /// Creative writing
        case ceativeWriting
        /// Summarise political event
        case summariseMeetingWithImage
        /// Search latest news
        case latestNewsInSydney
        /// Search and save results to GoogleSheets
        case saveSearchResultToGoogleSheets
        /// Plan a trip using search tools
        case tripPlanning
        /// Demo of using MCP Servers
        case getGitHubRepoTags
        /// Add image, text to Google Slides
        case addImageAndTextToSlides
        /// Auto generate Google slides for content
        case autoSlides
        /// Create Google docs
        case autoDocs

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
            case .autoSlides:
                """
                based on the following content to create a Google slides
                Please make the layout more easy to follow and beautiful
                Make title in deep blue color
                Do it step by step
                No need of images for now as Google requires image url and we don't support it yet now.
                <Content>
                **AI-generated models shake up the fashion industry and raise concerns (PBS NewsHour):**
                An article from PBS NewsHour discusses how AI-generated models are significantly impacting the fashion industry, from virtual fitting rooms to AI avatars in marketing. This shift is disrupting traditional workflows and raising concerns about potential job losses and other implications within the industry.

                **NHS to trial AI tool that speeds up hospital discharges (The Guardian):**
                The NHS is piloting an AI tool at Chelsea and Westminster NHS trust to accelerate hospital discharges by automating the completion of patient discharge documents. This initiative aims to reduce paperwork for doctors, free up beds, and ultimately cut patient waiting times, demonstrating AI's application in improving public services.

                **Catholic bioethics expert on AI: ‘It’s not too late to put the genie back in the bottle’ (Catholic News Agency):**
                A Catholic bioethics expert, Charles Camosy, warns about the dangers of widespread AI adoption, echoing Pope Leo XIV's concerns about its potential negative impact on human development and the "loss of the sense of the human." Camosy highlights the worrying blurring of lines between human and chatbot interaction, stressing the need to maintain the distinction of human identity.
                </Content>
                """
            case .addImageAndTextToSlides:
                """
                - Creates a slide in the Slides file
                - add text `Text added by AI` to the slide as title
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
            case .autoDocs:
                """
                Add the following content to the Google Docs document
                <Content>
                <title>AI-generated models shake up the fashion industry and raise concerns (PBS NewsHour)</title>
                An article from PBS NewsHour discusses how AI-generated models are significantly impacting the fashion industry, from virtual fitting rooms to AI avatars in marketing. This shift is disrupting traditional workflows and raising concerns about potential job losses and other implications within the industry.

                <title>NHS to trial AI tool that speeds up hospital discharges (The Guardian)</title>
                The NHS is piloting an AI tool at Chelsea and Westminster NHS trust to accelerate hospital discharges by automating the completion of patient discharge documents. This initiative aims to reduce paperwork for doctors, free up beds, and ultimately cut patient waiting times, demonstrating AI's application in improving public services.
                """
            }
        }

        func tools() throws -> [any AIAgentTool] {
            let baseFolder = "."
            let fileIO = FileIO(baseFolder: baseFolder)

            let fetchTool = Fetch()

            let googleServiceAccount =
                ProcessInfo.processInfo.environment["Google_Service_Account"] ?? ""
            let googleSheetId = ProcessInfo.processInfo.environment["Google_Sheet_ID"] ?? ""
            let googlePresentationId =
                ProcessInfo.processInfo.environment["Google_Presentation_ID"] ?? ""
            let googleDocumentId = ProcessInfo.processInfo.environment["Google_Document_ID"] ?? ""

            let cx = ProcessInfo.processInfo.environment["cx"] ?? ""
            let key = ProcessInfo.processInfo.environment["key"] ?? ""
            let googleSearch = GoogleSearch(cx: cx, key: key)

            let geminiImage = GeminiImage(apiKey: geminiAPIKey, baseFolder: baseFolder)
            let googleSheetsTool = try GoogleSheets(
                serviceAccount: googleServiceAccount, sheetId: googleSheetId)
            let googleSlidesTool = try GoogleSlides(
                serviceAccount: googleServiceAccount, presentationId: googlePresentationId)
            let googleDocsTool = try GoogleDocs(
                serviceAccount: googleServiceAccount, documentId: googleDocumentId)

            return switch self {
            case .summariseAIHistory: [fileIO, googleSearch]
            case .summariseMeetingWithImage: [fileIO, googleSearch, geminiImage]
            case .latestNewsInSydney: [fileIO, googleSearch]
            case .ceativeWriting: [fileIO]
            case .saveSearchResultToGoogleSheets: [fileIO, googleSearch, googleSheetsTool]
            case .tripPlanning: [fileIO, googleSearch, fetchTool]
            case .getGitHubRepoTags: []
            case .addImageAndTextToSlides: [googleSlidesTool]
            case .autoSlides: [googleSlidesTool]
            case .autoDocs: [googleDocsTool]
            }
        }

        func mcpServers() -> [MCPServer] {
            if self == .getGitHubRepoTags {
                let gitHubURL = URL(string: "https://api.githubcopilot.com/mcp/")!
                let gitHubToken = ProcessInfo.processInfo.environment["GitHubToken"] ?? ""
                return [.http(url: gitHubURL, token: gitHubToken)]
            }
            return []
        }
    }
    let model: AIAgentModel
    let managerAgent: AIAgent
    let goalManager: GoalManager

    static func run(example: AutoWorkflow.Example) async throws {
        let model = GeminiSDK(model: geminiModel, apiKey: geminiAPIKey)
        let autoWorkflow = try await AutoWorkflow(model: model, example: example)
        try await autoWorkflow.runInternal()
    }

    init(model: AIAgentModel, example: AutoWorkflow.Example) async throws {
        self.model = model
        self.managerAgent = try await AIAgent(title: "Manager", model: model)
        self.goalManager = GoalManager(
            goal: example.goal,
            managerAgent: managerAgent,
            models: [model],
            tools: try example.tools(),
            mcpServers: example.mcpServers())
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
