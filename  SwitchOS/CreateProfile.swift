//
//  CreateProfile.swift
//   SwitchOS
//
//  Created by Tim on 04.05.25.
//

import PhotosUI
import SwiftUI

struct CreateProfileView: View {
    @State var userName = ""
    @State var photosPickerItem: PhotosPickerItem?
    @State var imageData: Data?
    var body: some View {
        NavigationStack {
            Form {
                TextField("Username", text: $userName)
                PhotosPicker(selection: $photosPickerItem, label: {
                    HStack {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 25, height: 25)
                                .cornerRadius(25)
                        }
                        Text("Pick Profile Photo")
                    }
                })
                .onChange(of: photosPickerItem) { newPhoto in
                    if let newPhoto {
                        Task {
                            if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }
                }
                Button("Add User") {
                    if let imageData {
                        SwitchStorage.shared.addUser(userName, iconData: imageData)
                    }
                }
                .disabled(userName.isEmpty || imageData == nil)
            }
            .navigationTitle("Add New Profile")
        }
    }
}
