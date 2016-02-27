//
//  ViewController.swift
//  Füsic
//
//  Created by Cristian Alonso on 2/20/16.
//  Copyright © 2016 Cristian Alonso. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer


class ViewController: UIViewController, MPMediaPickerControllerDelegate {

    let scImg = UIImage(named: "scImg.png");
    let itImg = UIImage(named: "itImg.png");
    let scButton = UIButton(type: UIButtonType.Custom) as UIButton;
    let itButton = UIButton(type: UIButtonType.Custom) as UIButton;
    
    var picker = MPMediaPickerController.self(mediaTypes: .Music);

    
    var songData = NSData();
    
    
    func deleteFile(path: NSString) {
        if NSFileManager.defaultManager().fileExistsAtPath(path as String){
            do {
            try NSFileManager.defaultManager().removeItemAtPath(path as String)
            }
            catch {
                print("Can't Delete")
            }
            
        }
    }
    
    
    func postData() {
        
        
        
        let boundary = generateBoundaryString();
        let serverURL = NSURL(string: "http://10.132.1.253:3000/api/add");
        var request = NSMutableURLRequest(URL: serverURL!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 50);
        var startMPboundary:String = "--\(boundary)";
        var endMPboundary: String = "--\(boundary)--";
        
        var body = NSMutableString();
        body.appendFormat("\(startMPboundary)\r\n");
        body.appendFormat("Content-Disposition: form-data; name=\"source\"\r\n\r\n");
        body.appendFormat("file\r\n")
        body.appendFormat("\(startMPboundary)\r\n");
        body.appendFormat("Content-Disposition: form-data; name=\"song\"; filename=\"exported.mp3\"\r\n");
        body.appendFormat("Content-Type: audio/mp3\r\n\r\n");
        
        
        
        var endString = NSMutableString();
        endString.appendFormat("\(startMPboundary)\r\n");
        endString.appendFormat("Content-Disposition: form-data; name=\"Upload\"\r\n\r\n");
        endString.appendFormat("Submit\r\n");
        endString.appendFormat("\r\n\(endMPboundary)");
        
        var requestData = NSMutableData();
        requestData.appendData(body.dataUsingEncoding(NSUTF8StringEncoding)!);
        requestData.appendData(self.songData);
        requestData.appendData(endString.dataUsingEncoding(NSUTF8StringEncoding)!);
        
        var content = "multipart/form-data; boundary=\(boundary)";
        request.setValue(content, forHTTPHeaderField: "Content-Type");
        request.setValue("\(requestData.length)", forHTTPHeaderField: "Content-Length");
        request.HTTPBody = requestData;
        request.HTTPMethod = "POST";
        
        do {
            
            
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
                if error != nil{
                    print("Error -> \(error)")
                    return
                }
                
                do {
                    let result = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject]
                    
                    print("Result -> \(result)")
                    
                } catch {
                    print("Error -> \(error)")
                }
            }
            
            task.resume()
            
            
            
            
        } catch {
            print(error)
        }
        
        
    }
    
    
    //Function to allow a SoundCloud search and then extract the url to upload to the server
    func toSC() {
    
    }
    //Function to open the Music content and allow you to pick a song
    func toIT() {
        
        self.presentViewController(picker, animated: true, completion: nil);
        
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        self.dismissViewControllerAnimated(true, completion: nil);
        
       
        
        
        let mediaItem = mediaItemCollection.items[0];
        let itemURL = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL;
        let songAsset = AVURLAsset(URL: itemURL);
        let exporter = AVAssetExportSession.init(asset: songAsset, presetName: AVAssetExportPresetPassthrough);
        exporter!.outputFileType = "com.apple.quicktime-movie";
        let documents = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first
        let exportFile = documents!.stringByAppendingString("/exported.mp3.mov");
        deleteFile(exportFile);
        let exportURl = NSURL.fileURLWithPath(exportFile);
        exporter!.outputURL = exportURl;
        
        exporter?.exportAsynchronouslyWithCompletionHandler({
            let exportStatus = exporter!.status;
            
            switch (exportStatus) {
                
            case AVAssetExportSessionStatus.Completed:
                var audioPath = exportFile as NSString;
                audioPath = audioPath.stringByDeletingLastPathComponent;
                audioPath = audioPath.stringByAppendingString("/exported.mp3");
                
                do {
                    self.deleteFile(audioPath);
                    try NSFileManager.defaultManager().moveItemAtPath(exportFile, toPath: audioPath as String);
                }
                catch {
                    print("Something Failed");
                }
                let audioURL = NSURL.fileURLWithPath(audioPath as String);
                
                self.songData = NSData.init(contentsOfURL: audioURL)!;
                print("Exported Successfully!!!");
                self.postData();
                self.deleteFile(audioPath);
                break;
                
            case AVAssetExportSessionStatus.Failed:
                print("Failure to Export");
                break;
                
            case AVAssetExportSessionStatus.Unknown:
                print("???");
                break;
                
            default :
                
                break;
                
                
            }
            
            
            
            
        });
        
        
       
        
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
        
        
        
        
        
        
        
    
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        picker.delegate = self;
        picker.allowsPickingMultipleItems = false;
        
        self.view.backgroundColor = UIColor.grayColor();
        scButton.setBackgroundImage(scImg, forState: .Normal);
        itButton.setBackgroundImage(itImg, forState: .Normal);
        scButton.frame = CGRectMake(10,self.view.bounds.height-140,200,125);
        itButton.frame = CGRectMake(self.view.bounds.width-210,self.view.bounds.height-140,200,125);
        scButton.addTarget(self, action: Selector("toSC"), forControlEvents: .TouchUpInside);
        itButton.addTarget(self, action: Selector("toIT"), forControlEvents: .TouchUpInside);
        self.view.addSubview(scButton);
        self.view.addSubview(itButton);
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

