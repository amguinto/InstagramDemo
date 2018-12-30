//
//  ViewController.swift
//  InstagramDemo
//
//  Created by Andy Guinto on 11/12/18.
//  Copyright © 2018 Andy Guinto. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        
        return button
    }()
    
    //Info.plist : allow permissions
    @objc func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        //Allows Zooming, etc.
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    //Check which image was chosen.
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        plusPhotoButton.layer.cornerRadius = plusPhotoButton.frame.width / 2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.black.cgColor
        plusPhotoButton.layer.borderWidth = 3
        //Dismiss ImagePicker
        dismiss(animated: true, completion: nil)
    }
    
    let emailTextField: UITextField = {
        let emailBox = UITextField()
        emailBox.placeholder = "Email"

        return emailBox
    }()
    
    @objc func handleTextInputChange() {
        let isFormValid = emailTextField.text?.isEmpty == false && usernameTextField.text?.isEmpty == false && passwordTextField.text?.isEmpty == false
        
        if isFormValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = UIColor.init(displayP3Red: 17, green: 154, blue: 237, alpha: 0)
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.init(displayP3Red: 17, green: 154, blue: 237, alpha: 0)
        }
    }
    
    let usernameTextField: UITextField = {
        let usernameBox = UITextField()
        usernameBox.placeholder = "Username"

        return usernameBox
    }()
    
    let passwordTextField: UITextField = {
        let passwordBox = UITextField()
        passwordBox.placeholder = "Password"
        passwordBox.isSecureTextEntry = true

        return passwordBox
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        return button
    }()
    
    
    //TODO: Fix Errors
    @objc func handleSignUp() {
        guard let email = emailTextField.text, !email.isEmpty else { return }
        guard let username = usernameTextField.text, !username.isEmpty else { return }
        guard let password = passwordTextField.text, !password.isEmpty else { return }
        
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error: Error?) in
            
            if let err = error {
                print("Failed to create user:", err)
                return
            }
            
            print("Successfully created user:", user?.user.uid ?? "")
            
            guard let image = self.plusPhotoButton.imageView?.image else { return }
            
            guard let uploadData = image.jpegData(compressionQuality: 0.3) else { return }
            
            let filename = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference().child("profile_images").child(filename)
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                
                if let err = err {
                    print("Failed to upload profile image:", err)
                    return
                }
                
                // Firebase 5 Update: Must now retrieve downloadURL
                storageRef.downloadURL(completion: { (downloadURL, err) in
                    if let err = err {
                        print("Failed to fetch downloadURL:", err)
                        return
                    }
                    
                    guard let profileImageUrl = downloadURL?.absoluteString else { return }
                    
                    print("Successfully uploaded profile image:", profileImageUrl)
                    
                    guard let uid = user?.user.uid else { return }
                    
                    let dictionaryValues = ["username": username, "profileImageUrl": profileImageUrl]
                    let values = [uid: dictionaryValues]
                    
                    Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
                        
                        if let err = err {
                            print("Failed to save user info into db:", err)
                            return
                        }
                        
                        print("Successfully saved user info to db")
                        
                    })
                })
            })
            
        })
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(plusPhotoButton)
        
        //Photo Button anchor
        plusPhotoButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 140, center: view.centerXAnchor)
        
        setupInputFields()
        setupInputBoxFieldConstants(textField: emailTextField)
        setupInputBoxFieldConstants(textField: usernameTextField)
        setupInputBoxFieldConstants(textField: passwordTextField)
        
        setupButtonsConstants(button: signUpButton)
    }

    fileprivate func setupInputFields() {
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, signUpButton])
        
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 200)
        ])
    
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 200, center: nil)
    }
    
    func setupInputBoxFieldConstants(textField: UITextField) {
        
        textField.backgroundColor = UIColor(white: 0, alpha: 0.03)
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setupButtonsConstants(button: UIButton) {
        button.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
    }
}
