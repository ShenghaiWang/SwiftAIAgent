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
        case autoSlides

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
                Do it step by step
                No need of images for now as Google requires image url and we don't support it yet now.
                <Content>
                Here's a summary of recent AI/GenAI news in the last 24 hours:

                **AI-generated models shake up the fashion industry and raise concerns (PBS NewsHour):**
                An article from PBS NewsHour discusses how AI-generated models are significantly impacting the fashion industry, from virtual fitting rooms to AI avatars in marketing. This shift is disrupting traditional workflows and raising concerns about potential job losses and other implications within the industry.

                **NHS to trial AI tool that speeds up hospital discharges (The Guardian):**
                The NHS is piloting an AI tool at Chelsea and Westminster NHS trust to accelerate hospital discharges by automating the completion of patient discharge documents. This initiative aims to reduce paperwork for doctors, free up beds, and ultimately cut patient waiting times, demonstrating AI's application in improving public services.

                **Catholic bioethics expert on AI: ‘It’s not too late to put the genie back in the bottle’ (Catholic News Agency):**
                A Catholic bioethics expert, Charles Camosy, warns about the dangers of widespread AI adoption, echoing Pope Leo XIV's concerns about its potential negative impact on human development and the "loss of the sense of the human." Camosy highlights the worrying blurring of lines between human and chatbot interaction, stressing the need to maintain the distinction of human identity.

                **We are gen Z – and AI is our future. Will that be good or bad? (The Guardian):**
                A Guardian article presents diverse Gen Z perspectives on AI, highlighting both hopes and concerns. Key worries include the spread of misinformation through AI-generated content, the environmental impact of AI's energy demands, and the potential for AI in dating to reduce genuine human connection. Conversely, AI is viewed positively as a beneficial tool for enhancing journalism, fostering collaborative learning, and driving innovation in fields like architecture.

                **5 Artificial Intelligence (AI) Stocks to Buy and Hold for the Next Decade (Yahoo Finance - The Motley Fool):**
                The Motley Fool identifies five AI stocks – Nvidia, Taiwan Semiconductor, Amazon, Meta Platforms, and Alphabet – as strong long-term investments for the next decade, driven by the expanding artificial intelligence landscape. Nvidia and Taiwan Semiconductor are poised to benefit from the growing demand for AI computing power, while Meta Platforms and Alphabet are leveraging AI to enhance their advertising services, and Amazon's AWS is experiencing significant AI-related cloud computing demand.

                **Blue-collar jobs are gaining popularity as AI threatens office work (NBC News):**
                As AI continues to advance and potentially impact white-collar jobs, blue-collar and skilled trade professions are gaining popularity due to their perceived immunity to automation. Experts like Geoffrey Hinton suggest manual labor roles, such as plumbers, roofers, and nursing assistants, are less vulnerable to AI displacement compared to office-based roles like legal assistants or writers. A recent Microsoft list supports this, identifying various manual jobs as "safe" from AI threats.
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
