import UIKit
import Flutter
import ZendeskCoreSDK
import SupportProvidersSDK
import AnswerBotProvidersSDK
import AnswerBotSDK
import SupportSDK
import MessagingSDK
import ChatSDK
import ZDCChat
import MessagingAPI
import SDKConfigurations

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var container: ContainerViewController?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        configFlutter()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func configFlutter() {
        if let controller : FlutterViewController = self.window.rootViewController as? FlutterViewController {
            let channel : FlutterMethodChannel = FlutterMethodChannel(name: "flutterzendeskunified", binaryMessenger: controller.binaryMessenger)
            channel.setMethodCallHandler(onMethodCall(call:result:))
            
            container = ContainerViewController(delegate: self, flutterViewController: controller, messagingViewController: configZenDesk())
        }
    }
    
    private func configZenDesk() -> UIViewController {
        Zendesk.initialize(appId: "replace-it", clientId: "replace-it", zendeskUrl: "replace-it")
        Support.initialize(withZendesk: Zendesk.instance)
        AnswerBot.initialize(withZendesk: Zendesk.instance, support: Support.instance!)
        let identity = Identity.createAnonymous(name: "replace-it", email: "replace-it")
        Zendesk.instance?.setIdentity(identity)
        
        do {
            let messagingConfiguration = MessagingConfiguration()
            let supportEngine = try SupportEngine.engine()
            let answerBotEngine = try AnswerBotEngine.engine()
            let messagingViewController = try Messaging.instance.buildUI(engines: [answerBotEngine, supportEngine], configs: [messagingConfiguration])
            return messagingViewController
            
        } catch let error {
            print(error.localizedDescription)
        }
        
        return UIViewController()
    }
    
    private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "startZendesk") {
            startZendesk()
            //            startZendeskChat()
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startZendesk() {
        if let container = self.container {
            let navigation = UINavigationController(rootViewController: container)
            self.window.rootViewController = navigation
            self.window.makeKeyAndVisible()
        }
    }
    
    // Aqui é somente o zendesk chat e funciona perfeitamente
    // pois não é necessário um navigationController pra dispará-lo
    private func startZendeskChat() {
        ZDCChat.initialize(withAccountKey: "replace-it")
        let opt = ZDCChatView.appearance()
        if let textEntryView = opt.textEntryView {
            textEntryView.autoresizesSubviews = true
        }
        let visitorCell = ZDCVisitorChatCell.appearance()
        visitorCell.bubbleColor = .darkGray
        visitorCell.textColor = .white
        
        ZDCChat.start { config in
            config?.department = "Development"
            config?.tags = ["subscription", "mobile_app"]
            config?.preChatDataRequirements.email = .required
            config?.emailTranscriptAction = .neverSend
        }
    }
}

private class ContainerViewController: UIViewController {
    
    private let delegate: AppDelegate
    private let flutterViewController: FlutterViewController
    private let messagingViewController: UIViewController
    
    private var isShowingChat: Bool = false
    
    private var rootView: UIView = {
       let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    init(delegate: AppDelegate, flutterViewController: FlutterViewController, messagingViewController: UIViewController) {
        self.delegate = delegate
        self.flutterViewController = flutterViewController
        self.messagingViewController = messagingViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view = rootView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isShowingChat {
            delegate.window.rootViewController = flutterViewController
            delegate.window.makeKeyAndVisible()
        } else {
            configNavigationBar()
            // Se botar o animated: true vai abrir lateralmente
            // porém vai dar pra ver que tem uma tela a mais por baixo
            navigationController?.pushViewController(messagingViewController, animated: false)
        }
        isShowingChat.toggle()
        
    }
    
    // Aqui você configura as cores e demais itens
    // da navigation bar. :)
    private func configNavigationBar() {
        navigationController?.navigationBar.barTintColor = .red
        navigationController?.navigationBar.tintColor = .yellow
        navigationController?.navigationBar.backgroundColor = .orange
    }
}
