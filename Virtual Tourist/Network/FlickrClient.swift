//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/27/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: NSObject {
    
    var session = URLSession.shared
    
    static let sharedInstance = FlickrClient()
    
    func taskForSearch(_ methodParameters: [String:String], completionHandlerForSearch: @escaping (_ result: AnyObject?, _ error: NSError?, _ errorString: String?) -> Void) -> URLSessionTask {
        
        let request = NSURLRequest(url: flickrURLFromParameters(methodParameters))
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForSearch(nil, NSError(domain: "taskForSearch", code: 1, userInfo: userInfo), error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request")
                print("There was an error with request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard data != nil else {
                sendError("No data was returned by the request!")
                return
            }
            
            // parse the data
            self.parseDataWithCompletionHandler(data!, completionHandlerForParse: completionHandlerForSearch)
            
        }
        
        // start the task!
        task.resume()
        
        return task
        
    }
    
    func getURLArray(latitude: Double, longitude: Double, page: Int, _ completionHandlerForURLs: @escaping (_ success: Bool, _ results: [String]?, _ errorString: String?, _ randomPage: Int?) -> Void) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: String(page)
            ]
        
        print("bbox: \(bboxString(latitude: latitude, longitude: longitude))")
        
        let _ = taskForSearch(methodParameters) { (result, error, errorString) in
            
            func sendError(_ error: String) {
                print(error)
                completionHandlerForURLs(false, nil, error, 1)
                
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = result![Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(result)")
                return
            }
            
            guard let perPage = photosDictionary[Constants.FlickrResponseKeys.perPage] as? Int else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.perPage)' in \(result)")
                return
            }
            print("Photos per page: \(perPage)")
            
            guard let totalPhotos = photosDictionary[Constants.FlickrResponseKeys.Total] as? String else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Total)' in \(photosDictionary)")
                return
            }
            print("Real total photos: \(totalPhotos)")
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            print("Total photos in photoArray: \(photosArray.count)")
            
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
             //pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            var photoURLs = [String]()
            if photosArray.count == 0 {
                sendError("No Photos Found. Search Again.")
                return
            } else {
                let maxPhotos : Int = 100
                var indexSet = Set<Int>()
                
                while indexSet.count != maxPhotos {
                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    indexSet.insert(randomPhotoIndex)
                }
                print(indexSet)
                
                for index in indexSet {
                    let photo = photosArray[index] as [String: AnyObject]
                    if let urlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String {
                        photoURLs.append(urlString)
                    } else {
                        print("No URL found in photo")
                    }
                }

            }
            
            completionHandlerForURLs(true, photoURLs, nil, randomPage)
        }
    }
    
    func getImageData(_ url: URL, completionHandlerForGetImage: @escaping (_ data: Data?, _ error: NSError?, _ errorString: String?) -> Void) -> URLSessionTask {
        let task = session.dataTask(with: url) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGetImage(nil, NSError(domain: "getImageData", code: 1, userInfo: userInfo), error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request")
                print("There was an error with request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let imageData = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForGetImage(imageData, nil, nil)
        }
        
        
        // start the task!
        task.resume()
        return task
    
    }
    
    func parseDataWithCompletionHandler(_ data: Data, completionHandlerForParse: @escaping (_ result: AnyObject?, _ error: NSError?, _ errorString: String?) -> Void) {
        var parsedResult: [String:AnyObject]! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForParse(nil, NSError(domain: "parseDataWithCompletionHandler", code: 1, userInfo: userInfo), "Could not parse the data as JSON")
        }
        completionHandlerForParse(parsedResult as AnyObject, nil, nil)
    }
    
    private func bboxString(latitude: Double?, longitude: Double?) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = latitude, let longitude = longitude {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    private func flickrURLFromParameters(_ parameters: [String:String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
