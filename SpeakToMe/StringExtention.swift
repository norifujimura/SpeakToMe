//
//  StringExtention.swift
//  SpeakToMe
//
//  Created by Noriyuki Fujimura on 2018/10/24.
//  Copyright © 2018 Henry Mason. All rights reserved.
//

import Foundation

extension String {
    //https://ja.stackoverflow.com/questions/29675/%E6%96%87%E5%AD%97%E5%88%97%E3%81%AB%E6%8C%87%E5%AE%9A%E3%81%AE%E3%83%AF%E3%83%BC%E3%83%89%E3%81%8C%E4%BD%95%E5%80%8B%E5%90%AB%E3%81%BE%E3%82%8C%E3%82%8B%E3%81%8B%E3%82%AB%E3%82%A6%E3%83%B3%E3%83%88%E3%81%97%E3%81%9F%E3%81%84
    func numberOfOccurrences(of word: String) -> Int {
        var count = 0
        var nextRange = self.startIndex..<self.endIndex
        while let range = self.range(of: word, options: .caseInsensitive, range: nextRange) {
            count += 1
            nextRange = range.upperBound..<self.endIndex
        }
        return count
    }
    
    //returns index of start point of a bound
    func indicesOfOccurances(of word: String) -> [Int]{
        var indexes:[Int]=[];
        var nextRange = self.startIndex..<self.endIndex
        while let range = self.range(of: word, options: .caseInsensitive, range: nextRange) {
            //indexes.append(Int(range.lowerBound));
            let temp=self.endIndex.distance(to: range.upperBound);
            let index=self.count-temp;
            indexes.append(index);
            nextRange = range.upperBound..<self.endIndex;
        }
        return indexes;
    }
    
    func rangesOfOccurances(of word: String) -> [Range<String.Index>]{
        var ranges:[Range<String.Index>]=[];
        var nextRange = self.startIndex..<self.endIndex
        while let range = self.range(of: word, options: .caseInsensitive, range: nextRange) {
            ranges.append(range);
            nextRange = range.upperBound..<self.endIndex;
        }
        return ranges;
    }
    
}
