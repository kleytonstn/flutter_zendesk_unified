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
    
    private var navigationController : UINavigationController?
    private var savedFlutterViewController : FlutterViewController?
    private var timer = Timer()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        setFlutterChannel()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func setFlutterChannel() {
        if let controller : FlutterViewController = self.window.rootViewController as? FlutterViewController {
            self.savedFlutterViewController = controller
            let channel : FlutterMethodChannel = FlutterMethodChannel(name: "flutterzendeskunified", binaryMessenger: controller.binaryMessenger)
            channel.setMethodCallHandler(onMethodCall(call:result:))
        }
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
    
    // Este método vai pegar a engine do zendesk support e também a do answer bot e unificá-las
    // para uma execução em conjunto
    // É preciso usar um navigationcontroller para dar o push para a messagingViewController
    // Porém quando o usuário fecha a tela, não é retornado para o flutter, pois não se tem mais
    // a flutterViewController e aparece uma tela preta.
    private func startZendesk() {
            Zendesk.initialize(appId: "replace-it", clientId: "replace-it", zendeskUrl: "replace-it")
            Support.initialize(withZendesk: Zendesk.instance)
            AnswerBot.initialize(withZendesk: Zendesk.instance, support: Support.instance!)
            let identity = Identity.createAnonymous(name: "Kleyton", email: "kleyton.nascimento@napista.com.br")
            Zendesk.instance?.setIdentity(identity)
                    
            do {
                let messagingConfiguration = MessagingConfiguration()
                let supportEngine = try SupportEngine.engine()
                let answerBotEngine = try AnswerBotEngine.engine()
                let messagingViewController = try Messaging.instance.buildUI(engines: [answerBotEngine, supportEngine], configs: [messagingConfiguration])
                
                // Aqui está sendo criado um navigationController para que seja possível utilizar o push
                if let flutterViewController = FlutterViewController() as? UIViewController {
                    self.navigationController = UINavigationController(rootViewController: flutterViewController)
                    
                    self.window = UIWindow(frame: UIScreen.main.bounds)
                    self.window.rootViewController = self.navigationController
                    self.window.makeKeyAndVisible()
                    
                    scheduleCheckController()
                    
                    self.navigationController?.pushViewController(messagingViewController, animated: true)
                    //self.navigationController?.present(messagingViewController, animated: true, completion: scheduleCheckController)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        // Esta função fica repetidamente disparando a função checkController
        // Neste caso, em 5 segundos ela trará o usuário de volta pra viewController do flutter
        func scheduleCheckController() {
            timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkController), userInfo: nil, repeats: true)
        }
        
        // Esta função tráz de volta a viewcontroller do flutter, porém não consegui pegar o evento exato de quando o
        // usuário fecha a tela do messagingViewController, imaginei que fosse o isMovingToParent mas não surte o efeito desejado
        // portanto, não se sabe em que momento devemos trazer o savedFlutterViewController de volta
        @objc func checkController() {
            print("checking...")
            self.window.rootViewController = savedFlutterViewController
            self.window.makeKeyAndVisible()
            timer.invalidate()
            if let _isBeingDismissed = self.navigationController?.isBeingDismissed {
                if (_isBeingDismissed) {
                    print("isBeingDismissed")
                    self.window.rootViewController = savedFlutterViewController
                    self.window.makeKeyAndVisible()
                    timer.invalidate()
                } else {
                    print("NOT isBeingDismissed")
                }
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
