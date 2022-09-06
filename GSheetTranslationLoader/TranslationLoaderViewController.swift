//
//  ViewController.swift
//  GSheetTranslationLoader
//
//  Created by Anas Sharif on 03/07/2021.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import Firebase
import NVActivityIndicatorView

class TranslationLoaderViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheetsReadonly]
    private let service = GTLRSheetsService()
    var signInButton: GIDSignInButton!
    @IBOutlet weak var translationType: UISegmentedControl!
    let output = UITextView()
    var fileName = "Localizable.strings"
    let iconFileName = "InfoPlist.strings"
    let flag: Bool = false
    let myG = DispatchGroup()
    var currentIndex: Int = 0
    var dicName = ""
    var columeIndex = 1
    private var startingRow = 0
    
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    @IBOutlet weak var genrateFilesBtn: UIButton!
    
    let forbidKeys = ["time"]
    
    let listForIos: [(String,String)] = [("en", "C") , ("de", "D"), ("pt","E"), ("sv","F"), ("es","G"), ("fr","H"), ("it","I"), ("zh-Hans","J"),  ("ar-SA","K"), ("ja","L"), ("ko-KP","M"), ("uk","N"), ("hi","O"),("th-TH","P"), ("nl-NL","Q") ,("ru-RU","R"), ("el-GR","S"), ("id","T"),
                                  ("bn","U"), ("mn","V"), ("vi","W"), ("pa","X")]
    
    
    let listForAndroid: [(String,String)] = [("en", "C") ,
                                             ("de", "D"),
                                             ("pt","E"),
                                             ("sv","F"),
                                             ("es","G"),
                                             ("fr","H"),
                                             ("it","I"),
                                             ("zh","J"),
                                             ("ar-rSA","K"),
                                             ("ja","L"),
                                             ("ko-rKP","M"),
                                             ("uk","N"),
                                             ("hi","O"),
                                             ("th-rTH","P"),
                                             ("nl-rNL","Q") ,
                                             ("ru","R"),
                                             ("el-rGR","S"),
                                             ("in-rID","T"),
                                             ("bn-rBD","U"),
                                             ("mn","V"),
                                             ("vi","W"),
                                             ("pa","X")]
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton = GIDSignInButton(frame: CGRect(x: (view.frame.width * 0.5) - 50, y: view.frame.height * 0.5, width: 0, height: 0))
            // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        // Add a UITextView to display output.
        output.frame = view.bounds
        output.isEditable = false
//        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
//        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        output.isHidden = true
        view.addSubview(output)
        // Add the sign-in button.
        view.addSubview(signInButton)
    }
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            UIView.animate(withDuration: 0.8, animations: {
                self.signInButton.frame.origin.x = self.view.frame.width + 50
            }, completion: { (success) in
                if success {
                    
                }
            })
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            genrateFilesBtn.isHidden = false
        }
    }
    func listyCounter(){
        var value = listForIos
        if self.translationType.selectedSegmentIndex == 1 {
            value = listForAndroid
        }
        if currentIndex < value.count
        {
            listMajors(value)
        }
        else{
            genrateFilesBtn.setTitle("Translation Loaded!", for: .normal)
            indicatorView.isHidden = true
            indicatorView.stopAnimating()
            self.translationType.isUserInteractionEnabled = true
        }
    }
    @IBAction func queryBtn(_ sender: UIButton) {
        genrateFilesBtn.setTitle("Translation Loading..", for: .normal)
        self.translationType.isUserInteractionEnabled = false
       
        indicatorView.isHidden = false
        indicatorView.color = .red
        indicatorView.type = .ballClipRotatePulse
        indicatorView.startAnimating()
        listyCounter()
        
    }
    @objc func translationQueryToGoogleSheet(){
        
    }
    func listMajors(_ columnsList: [(String, String)]) {
        
        let column =  columnsList[currentIndex]
        self.dicName = column.0
        output.text = "Loading tranlations..."
        let spreadsheetId = "15CxZnXG5_3fAnMX06a3qet17rRRTMi0meaIzNCv20ls"
        let range = "B2:\(column.1)"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: spreadsheetId, range:range)
        query.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Columns
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:)))
       // self.output.isHidden = false
    }
    @objc func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRSheets_ValueRange,
                                 error : NSError?) {
        
       
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        var majorsString = ""
        var iconString = ""
        var columns = result.values!
        result.values?.removeAll()
        
        if columns.isEmpty {
            output.text = "Data not found."
            return
        }
            let keys = columns[0]
            let major = columns[columeIndex]
            let key = keys.count
        if key == major.count{
        if !keys.isEmpty, !major.isEmpty {
            let key = keys.count
            for i in startingRow..<key{
                let n = String(describing: keys[i])
                let m = String(describing:  major[i])
               
                if self.translationType.selectedSegmentIndex == 0 {
                    if n == "spectrum_icon_name" {
                        iconString += "\"CFBundleDisplayName\" = \"iGenapps\";\n"
                        iconString += "\"CFBundleName\" = \"iGenapps\";\n"
                        continue
                    }
                    if n == "short_text_recommend" {
                         let dots = #"\"...\""#
                        majorsString += "\"\(n)\" = \"\(m.capitalizingFirstLetter()) \(dots). \";\n"
                    }else{
                        majorsString += "\"\(n)\" = \"\(m.capitalizingFirstLetter())\";\n"
                    }
                   
                }else{
                    let key = n
                    var value =
                        m.capitalizingFirstLetter()
                    if value.contains("&") {
                        value = m.capitalizingFirstLetter().replacingOccurrences(of: "&", with: "&amp;")
                    }
                    if value.contains(" & ") {
                        value = m.capitalizingFirstLetter().replacingOccurrences(of: " & ", with: "&amp;")
                    }
                    if value.contains("\'") {
                        value =
                            m.capitalizingFirstLetter().replacingOccurrences(of: "\'", with: "\\'")
                    }
                    if value.contains("\"") {
                        value =
                            m.capitalizingFirstLetter().replacingOccurrences(of: "\"", with: "\"")
                    }
                    if value.contains("@") {
                        value =
                            m.capitalizingFirstLetter().replacingOccurrences(of: "@", with: "")
                    }
                    
                    if !forbidKeys.contains(key) {
                        majorsString += "<string name=\"\(key)\" formatted=\"false\">\(value)</string>\n"
                    }
                
                }
               
            }
        }
        columeIndex = columeIndex + 1
        self.dictoryForTranslations(dicName, majorsString, iconString)
        self.currentIndex = self.currentIndex + 1
        self.listyCounter()
        }else{
            showAlert(title: "Error", message: "Your colums of keys not equal to colums of values please check your sheet and correct it.")
            output.text = "Try Again"
            indicatorView.stopAnimating()
        }
    }
   @objc func dictoryForTranslations( _ dicName: String, _ mainString:String, _ appNameString:String ){
        if dicName.isEmpty{
             return
        }
    var writeAbleString = mainString
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            var filePath =  tDocumentDirectory.appendingPathComponent("\(dicName).lproj")
            if self.translationType.selectedSegmentIndex == 1 {
                filePath =  tDocumentDirectory.appendingPathComponent("values-\(dicName)")
//                let xmlVersion = "<?xml version= \"1.0\" encoding=\"utf-8\"?>\n"
                writeAbleString = "<resources>\n\(mainString)\n</resources>"
                fileName = "strings.xml"
            }
//            filePath = URL(string:  "/Users/usmanmughal/Desktop/Projects/swiftapper-igenapps/Apper/\(dicName).lproj")!
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                    try writeAbleString.write(to: filePath.appendingPathComponent(fileName) , atomically: true, encoding: .utf8)
                    if self.translationType.selectedSegmentIndex == 0 {
                        try appNameString.write(to:filePath.appendingPathComponent(iconFileName) , atomically: true, encoding: .utf8)
                    }
                   
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }else{
                do {
                    let appendingPath = filePath.appendingPathComponent(fileName)
                    try writeAbleString.write(to: appendingPath , atomically: true, encoding: .utf8)
                    if self.translationType.selectedSegmentIndex == 0 {
                        try appNameString.write(to:filePath.appendingPathComponent(iconFileName) , atomically: true, encoding: .utf8)
                    }
                   
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(filePath)")
            
        }
        
    }
    // Helper for showing an alert
   @objc func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

}
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

