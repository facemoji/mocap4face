/*
 See LICENSE.md for this sample’s licensing information.
*/

import Foundation
import UIKit

public class ProgressCell : UICollectionViewCell {
    @IBOutlet weak var name: UILabel?
    @IBOutlet weak var progress : UIProgressView?
}

public class TableDataSource : NSObject, UICollectionViewDataSource {
    private var data: [(String, Float)] = []
    private var blendshapeNames: [String] = []
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "progressCell", for: indexPath)
        if let pc = cell as? ProgressCell {
            pc.name?.text = data[indexPath.row].0
            pc.progress?.progress = data[indexPath.row].1
        }
        
        return cell
    }

    
    func setBlendshapeNames(_ names: [String]) {
        blendshapeNames = names.sorted()
    }
    
    func setData(_ data: [String:Float]) {
        self.data = blendshapeNames.map({($0, data[$0] ?? 0)})
    }
}
