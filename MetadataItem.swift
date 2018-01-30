//
//  MetadataItem.swift
//  Vinyl Recorder
//
//  Created by Ramon Haro Marques on 17/01/2018.
//  Copyright © 2018 Convert Technologies. All rights reserved.
//

import UIKit
import AVFoundation


enum AudioMediaType:String{
    case mp3 = "mp3"
    case aac = "aac"
    case alac = "alac"
    case invalid = "invalid"
}


class MetadataItem: NSObject {
    
    //MARK:- Variables
    //MARK: Constants
    let logClassName = String(describing:MetadataItem.self)
    
    
    //MARK: Vars
    var title:String?
    var albumName:String?
    var artistName:String?
    
    var genre:String?
    var year:Int?
    var fileType = AudioMediaType.invalid
    
    var tracKNumber:Int?
    var discNumber:Int?
    
    var artwork:Data?
    var url:URL
    
    
    //MARK:- Constructor
    required init(withUR url:URL) {
        
        self.url = url
        super.init()
        
    }
    
    
    
    //MARK:- Methods
    func getMetadata()->MetadataItem?{
        
        do{
            let audioFile = try AVAudioFile.init(forReading: url)
            let audioFileProcessingFormat = audioFile.fileFormat
            let audioFileSettings = audioFileProcessingFormat.settings
            
            let audioAsset = AVAsset.init(url: url)
            
            fileType = getExtension(withId: audioFileSettings[AVFormatIDKey] as? AudioFormatID)
            switch fileType{
            case .mp3:
                return getId3Metadata(id3MetadataArray: audioAsset.metadata(forFormat: .id3Metadata))
            case .aac:
                return getItunesMetadata(itunesMetadataArray: audioAsset.metadata(forFormat: .iTunesMetadata))
            case .alac:
                return getItunesMetadata(itunesMetadataArray: audioAsset.metadata(forFormat: .iTunesMetadata))
            case .invalid:
                return nil
            }
            
        }
        catch{
            return nil
        }
        
    }
    
    func getExtension(withId value:AudioFormatID?)->AudioMediaType{
        
        if let valueId = value{
            switch valueId {
            case kAudioFormatMPEG4AAC:
                return .aac
            case kAudioFormatMPEGLayer3:
                return .mp3
            case kAudioFormatAppleLossless:
                return .alac
            default:
                return .invalid
            }
        }
        else{
            return .invalid
        }
        
    }
    
    func getItunesMetadata(itunesMetadataArray:[AVMetadataItem])->MetadataItem{
        
        //print("\(logClassName): getItunesMetadata ")
        
        let dummyId = AVMetadataIdentifier(rawValue: "")
        for itunesMetadata in itunesMetadataArray{
            
            let metadataIdentifier = itunesMetadata.identifier ?? dummyId
            
            //Title
            if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataSongName{
                //print("\(logClassName): getItunesMetadata -> Title = \(String(describing: itunesMetadata.value))")
                title = itunesMetadata.value as? String
            }
                //Album
            else if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataAlbum{
                //print("\(logClassName): getItunesMetadata -> Album = \(String(describing: itunesMetadata.value))")
                albumName = itunesMetadata.value as? String
            }
                //Artist
            else if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataArtist{
                //print("\(logClassName): getItunesMetadata -> Artist = \(String(describing: itunesMetadata.value))")
                artistName = itunesMetadata.value as? String
            }
                
                //genre
            else if metadataIdentifier == .iTunesMetadataPredefinedGenre || metadataIdentifier == .iTunesMetadataUserGenre{
                
                /*WE Have 2 different cases here:
                 1. iTunesMetadataPredefinedGenre => The genre was in the truck => http://id3.org/id3v2.3.0
                 2. iTunesMetadataPredefinedGenre => The genre has been modified using itunes options
                 */
                
                if metadataIdentifier == .iTunesMetadataPredefinedGenre{
                    let value = (itunesMetadata.value as! NSData).hash
                    genre = String(value)
                    //print("\(logClassName): getItunesMetadata -> genre iTunesMetadataPredefinedGenre = \(value)")
                }
                else if metadataIdentifier == .iTunesMetadataUserGenre{
                    //print("\(logClassName): getItunesMetadata -> genre iTunesMetadataUserGenre = \(String(describing: itunesMetadata.value!))")
                    genre = itunesMetadata.value as? String
                }
                else{
                    genre = "Other"
                }
                
            }
                //year
            else if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataReleaseDate{
                
                let pulledDate = itunesMetadata.value?.description
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
                
                if let date = dateFormatter.date(from: pulledDate ?? ""){
                    let units: Set<Calendar.Component> = [.year]
                    let comps = Calendar.current.dateComponents(units, from: date)
                    //print("\(logClassName): getItunesMetadata -> Date = \(String(describing: comps.year))")
                    year = comps.year
                }
                else{
                    //print("\(logClassName): getItunesMetadata -> Year = \(String(describing: Int((itunesMetadata.value?.description) ?? "0")))")
                    year = Int((itunesMetadata.value?.description) ?? "0")
                }
            }
                
                //tracKNumber
            else if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataTrackNumber{
                if var valueString:String = itunesMetadata.value?.description{
                    
                    valueString = valueString.replacingOccurrences(of: "<", with: "")
                    valueString = valueString.replacingOccurrences(of: ">", with: "")
                    
                    let valueStringArray = valueString.split(separator: " ")
                    //print("\(logClassName): getItunesMetadata -> tracKNumber = \(String(describing: Int(valueStringArray[0], radix: 16)))")
                    tracKNumber = Int(valueStringArray[0], radix: 16)
                    
                }
                
            }
                //diskNumber
            else if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataDiscNumber{
                
                if var valueString:String = itunesMetadata.value?.description{
                    valueString = valueString.replacingOccurrences(of: "<", with: "")
                    valueString = valueString.replacingOccurrences(of: ">", with: "")
                    
                    let valueStringArray = valueString.split(separator: " ")
                    //print("\(logClassName): getItunesMetadata -> Disc Number = \(String(describing: Int(valueStringArray[0], radix: 16)))")
                    discNumber = Int(valueStringArray[0], radix: 16)
                    
                }
                
            }
                
                //artwork
            else if metadataIdentifier == AVMetadataIdentifier.iTunesMetadataCoverArt{
                //print("\(logClassName): getItunesMetadata -> Cover Art)")
                artistName = itunesMetadata.value as? String
                artwork = (itunesMetadata.value as! NSData as Data)
            }
            
        }
        
        return self
        
    }
    
    func getId3Metadata(id3MetadataArray:[AVMetadataItem])->MetadataItem{
        
        //print("\(logClassName): getId3Metadata ")
        let dummyId = AVMetadataIdentifier(rawValue: "")
        
        for id3Metadata in id3MetadataArray{
            let metadataIdentifier = id3Metadata.identifier ?? dummyId
            
            //print("\(metadataIdentifier) VS \(AVMetadataKey.id3MetadataKeyRecordingTime) With Value = \(String(describing: id3Metadata.value?.description))")
            //print("\(AVMetadataKey.id3MetadataKeyRecordingTime) VS \(AVMetadataIdentifier.id3MetadataRecordingTime.rawValue) aganst \(metadataIdentifier.rawValue)")
            
            //Title
            if metadataIdentifier == .id3MetadataTitleDescription{
                //print("\(logClassName): getId3Metadata -> Title = \(String(describing: id3Metadata.value?.description))")
                title = id3Metadata.value?.description
            }
            //Album
            else if metadataIdentifier == .id3MetadataAlbumTitle{
                //print("\(logClassName): getId3Metadata -> Album = \(String(describing: id3Metadata.value?.description))")
                albumName = id3Metadata.value?.description
            }
                //Artist
            else if metadataIdentifier == .id3MetadataLeadPerformer{
                //print("\(logClassName): getId3Metadata -> Artist = \(String(describing: id3Metadata.value?.description))")
                artistName = id3Metadata.value?.description
            }
                
                //Genre
            else if metadataIdentifier == .id3MetadataContentType{
                //print("\(logClassName): getId3Metadata -> Genre = \(String(describing: id3Metadata.value?.description))")
                genre = id3Metadata.value?.description
            }
                //YEAR
            else if metadataIdentifier == AVMetadataIdentifier.id3MetadataOriginalReleaseTime || metadataIdentifier == AVMetadataIdentifier.id3MetadataRecordingTime{
                
                if let dateString = id3Metadata.value?.description{
                    let dateStringArray = dateString.split(separator: "-")
                    //print("\(logClassName): getId3Metadata -> Year = \(dateStringArray[0])")
                    year = Int(dateStringArray[0])
                }
                
            }
                
                //Track Number
            else if metadataIdentifier == .id3MetadataTrackNumber{
                
                if let trackString = id3Metadata.value?.description{
                    let trackStringArray = trackString.split(separator: "/")
                    //print("\(logClassName): getId3Metadata -> Track = \(trackStringArray[0])")
                    tracKNumber = Int(trackStringArray[0])
                }
                
            }
                //Track Disck
            else if metadataIdentifier == .id3MetadataPartOfASet{
                
                if let discString = id3Metadata.value?.description{
                    let discStringArray = discString.split(separator: "/")
                    //print("\(logClassName): getId3Metadata -> Disc Number = \(discStringArray[0])")
                    discNumber = Int(discStringArray[0])
                }
                
            }
                
                //Artwork
            else if metadataIdentifier == .id3MetadataAttachedPicture{
                
                if let imageData = id3Metadata.value as? Data{
                    if let _ = UIImage.init(data: imageData){
                        //print("\(logClassName) getId3Metadata -> AttachedPicture")
                        artwork = imageData
                    }
                }
            }
                
                //Private looking for image
            else if metadataIdentifier == .id3MetadataPrivate{
                
                if let imageData = id3Metadata.value as? Data{
                    if let _ = UIImage.init(data: imageData){
                        //print("\(logClassName) getId3Metadata -> AttachedPictureFromPrivate!!!")
                        artwork = imageData
                    }
                }
                
            }
            
        }
        
        return self
        
    }

}
