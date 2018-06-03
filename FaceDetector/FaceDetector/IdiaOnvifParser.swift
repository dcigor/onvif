//
//  IdiaOnvifParser.swift
//  FaceDetector
//
//  Created by Igor Diakov on 6/3/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

import Foundation
import AppKit

@objc class IdiaOnvifParser : NSObject {
    func parseUrl(url: String, username: String, password: String, block : @escaping (String?, String?) -> ()) {
        let camera = ONVIFCamera(with: url, credential: (login: username, password: password))
        camera.getServices {
            camera.getCameraInformation(callback: { (camera) in
                camera.getProfiles(profiles: { (profiles) in
                    if profiles.count > 0 {
                        let alert = NSAlert()
                        alert.messageText = "Select Profile"
                        alert.alertStyle  = .informational
                        for profile in profiles {
                            alert.addButton(withTitle: profile.name)
                        }
                        let i = alert.runModal() - NSAlertFirstButtonReturn
                        camera.getStreamURI(with: profiles[i].token, uri: { (uri) in
                            block(uri, nil)
                        })
                    }
                })
            }) { (error) in
                block(nil, "error \(error)")
            }
        }
    }
}
