//
//  LocationSearchViewModel.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/3/24.
//

import SwiftUI
import MapKit

class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    
    private var searchCompleter: MKLocalSearchCompleter
    
    override init() {
        self.searchCompleter = MKLocalSearchCompleter()
        super.init() // Call to NSObject's initializer
        self.searchCompleter.delegate = self  // Setting self as delegate
        self.searchCompleter.resultTypes = .address
    }
    
    func updateSearchResults() {
        searchCompleter.queryFragment = searchText
    }
    
}


extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Failed to find search results: \(error.localizedDescription)")
    }
}
