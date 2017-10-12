//
//  RegistrationVC.swift
//  krugozor-visitorsApp
//
//  Created by Stanly Shiyanovskiy on 26.09.17.
//  Copyright © 2017 oneByteCode. All rights reserved.
//

import UIKit

class RegistrationVC: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static func storyboardInstance() -> RegistrationVC? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "RegistrationVC") as? RegistrationVC
    }
    
    // MARK: - Properties -
    var isKBShown: Bool = false
    var kbFrameSize: CGFloat = 0
    var popDatePicker : PopDatePicker?
    var userModule: UserModuleProtocol!
    var model: RegistrationModel!
    
    // MARK: - Outlets -
    @IBOutlet weak var nameTF: UITextField! { didSet { nameTF.useUnderline() } }
    
    @IBOutlet weak var lastNameTF: UITextField! { didSet { lastNameTF.useUnderline() } }
    
    @IBOutlet weak var phoneTF: UITextField! { didSet { phoneTF.useUnderline() } }
    
    @IBOutlet weak var ageTF: UITextField! { didSet { ageTF.useUnderline() } }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var avatarImg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneTF?.addPoleForButtonsToKeyboard(myAction: #selector(phoneTF.resignFirstResponder), buttonNeeds: true)
        ageTF?.addPoleForButtonsToKeyboard(myAction: #selector(ageTF.resignFirstResponder), buttonNeeds: true)
        popDatePicker = PopDatePicker(forTextField: ageTF)
        // imgUser gesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        avatarImg?.isUserInteractionEnabled = true
        avatarImg?.addGestureRecognizer(tapGestureRecognizer)
        
        registerForKeyboardNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        removeKeyboardNotifications()
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func kbWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        let kbFrame = (userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        kbFrameSize = kbFrame.height
        UIView.animate(withDuration:0.3) {
            if !self.isKBShown {
                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.kbFrameSize, right: 0)
                self.scrollView.contentInset = contentInsets
            }
        }
        self.isKBShown = true
    }
    
    @objc func kbWillHide() {
        UIView.animate(withDuration:0.3) {
            if self.isKBShown {
                self.scrollView.contentInset = .zero
            }
        }
        self.isKBShown = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        avatarImg.image = info[UIImagePickerControllerEditedImage] as? UIImage
        avatarImg.contentMode = .scaleAspectFill
        avatarImg.layer.cornerRadius = avatarImg.frame.height / 2
        avatarImg.clipsToBounds = true
        model.userDataStruct.photoImageOrigin = UIImageJPEGRepresentation(avatarImg.image!, 1.0)
        dismiss(animated: true, completion: nil)
    }
    
    func chooseImagePickerAction(source: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - Actions -
    @IBAction func registerBtn(_ sender: UIButton) {
        self.view.endEditing(true)
        sendUserData ()
    }
    
    /// Send User Data to Server
    private func sendUserData () {
        if fieldsCheck() {
            userModule = UserModule()
            //FIXME: - Отправлять настоящую юзер дату, заполни там все поля втч session
            userModule.registrationNewUser(newUser: model.userDataStruct) // заменить UserDataStruct() на сконфигурированный тип
            segueToAppMainMenu ()
        } else {
            errorAlert(title: "Ошибка!", message: "Поля не могут быть пустыми!", actionTitle: "ОК")
        }
    }
    
    /// Segue to TabBarViewController
    private func segueToAppMainMenu () {
        if let newVC = TabBarViewController.storyboardInstance() {
            self.present(newVC, animated: true, completion: nil)
        }
    }
    
    //Дописал метод с проверками
    /// Checking user input fields - Доработать
    func fieldsCheck () -> Bool {
        return model.checkAllFields()
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let ac = UIAlertController(title: "Select images source", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) in
            self.chooseImagePickerAction(source: .camera)
        }
        let photoLibAction = UIAlertAction(title: "Photos", style: .default) { (_) in
            self.chooseImagePickerAction(source: .photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(cameraAction)
        ac.addAction(photoLibAction)
        ac.addAction(cancelAction)
        self.present(ac, animated: true, completion: nil)
    }
    
    // MARK: - TextFieldDelegate -
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func resign() {
        nameTF.resignFirstResponder()
        lastNameTF.resignFirstResponder()
        phoneTF.resignFirstResponder()
        ageTF.resignFirstResponder()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if (textField === ageTF) {
            resign()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let initDate : Date? = formatter.date(from: ageTF.text!)
            
            let dataChangedCallback : PopDatePicker.PopDatePickerCallback = { (newDate : Date, forTextField : UITextField) -> () in
                
                forTextField.text = (newDate.toString() ?? "?") as String
                self.model.userDataStruct.birthDate = forTextField.text 
            }
            
            popDatePicker!.pick(self, initDate: initDate, dataChanged: dataChangedCallback)
            
            return false
        }
        else {
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTF {
            nameTF.resignFirstResponder()
            lastNameTF.becomeFirstResponder()
        } else if textField == lastNameTF {
            lastNameTF.resignFirstResponder()
            phoneTF.becomeFirstResponder()
        } else if textField == phoneTF {
            phoneTF.resignFirstResponder()
            ageTF.becomeFirstResponder()
        } else {
            ageTF.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == phoneTF {
            let result = String().checkPhoneNumber(textField.text!, in: range, replacement: string)
            textField.text = result.1
            return result.0
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == phoneTF && textField.text == "" {
            textField.text = "+7 "
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if textField == nameTF {
            model.userDataStruct.name = nameTF.text!
        } else if textField == phoneTF {
            model.userDataStruct.phoneNumber = phoneTF.text!
        } else if textField == lastNameTF {
            model.userDataStruct.surname = lastNameTF.text!
        }
    }
    
    // MARK: - Private methods -
    func errorAlert(title: String, message: String, actionTitle: String) {
        let alertView = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle:. alert)
        let okAction = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alertView.addAction(okAction)
        present(alertView, animated: true, completion: nil)
    }
}
