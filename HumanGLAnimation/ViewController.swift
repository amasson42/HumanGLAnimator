//
//  ViewController.swift
//  HumanGLAnimation
//
//  Created by Arthur MASSON on 5/17/19.
//  Copyright © 2019 Arthur MASSON. All rights reserved.
//

import Cocoa
import SceneKit

import simd

// TODO: add torse position

extension float3: CustomStringConvertible {
    public var description: String {
        return "{\(self.x);\(self.y);\(self.z)}"
    }
}

class HGLKeyframe {
    
    static let pivotsNames = [
        "torse", "cou",
        "epaulegauche", "coudegauche",
        "epauledroite", "coudedroit",
        "jambegauche", "genougauche",
        "jambedroite", "genoudroit"
    ]
    
    static var pivotsNodes: [SCNNode] = []
    
    static func indexOf(pivotNamed name: String) -> Int? {
        return pivotsNames.index(where: {$0 == name})
    }
    
    static func nameOf(pivotAt index: Int) -> String? {
        guard index >= 0 && index < pivotsNames.count else {
            return nil
        }
        return pivotsNames[index]
    }
    
    static func initPivotsNodes(fromScene scene: SCNScene) {
        for name in pivotsNames {
            let node = scene.rootNode.childNode(withName: name, recursively: true)!
            pivotsNodes.append(node)
        }
    }
    
    var time: TimeInterval = 0
    
    var pivots: [float3] = [float3](repeating: float3(0), count: 10)
    
}

weak var currentViewController: ViewController?

class ViewController: NSViewController {
    
    @IBOutlet weak var humanSceneView: SCNView!
    @IBOutlet weak var keyframesTableView: NSTableView!
    
    @IBOutlet weak var frameTimeField: NSTextField!
    @IBOutlet weak var removeFrameButton: NSButton!
    
    @IBOutlet weak var attributesStackView: NSStackView!
    @IBOutlet weak var timeField: NSTextField!
    
    var keyFrames: [HGLKeyframe] = []
    
    var cameraPivot: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentViewController = self
        let scene = SCNScene(named: "Human.scn")!
        HGLKeyframe.initPivotsNodes(fromScene: scene)
        cameraPivot = scene.rootNode.childNode(withName: "camera_pivot", recursively: true)!
        humanSceneView.scene = scene
        humanSceneView.allowsCameraControl = false
        humanSceneView.autoenablesDefaultLighting = true
        
        keyframesTableView.dataSource = self
        keyframesTableView.delegate = self
        
        reloadUI()
        
        // Do any additional setup after loading the view.
    }
    
    func reloadUI() {
        
        self.keyFrames.sort(by: {return $0.time < $1.time})
        self.keyframesTableView.reloadData()
        let row = self.keyframesTableView.selectedRow
        let sup = row >= 0
        
        // time and remove button
        self.removeFrameButton.isEnabled = sup
        self.timeField.isEnabled = sup
        if sup {
            self.timeField.stringValue = self.keyFrames[row].time.description
        }
        
        // pivots attributes
        for (pivotIndex, stack) in self.attributesStackView.views.enumerated() {
            let stackView = stack as! NSStackView
            if sup {
                (stackView.views[1] as! NSTextField).stringValue = self.keyFrames[row].pivots[pivotIndex].x.description
                (stackView.views[2] as! NSTextField).stringValue = self.keyFrames[row].pivots[pivotIndex].y.description
                (stackView.views[3] as! NSTextField).stringValue = self.keyFrames[row].pivots[pivotIndex].z.description
                (stackView.views[1] as! NSTextField).isEnabled = true
                (stackView.views[2] as! NSTextField).isEnabled = true
                (stackView.views[3] as! NSTextField).isEnabled = true
            } else {
                (stackView.views[1] as! NSTextField).isEnabled = false
                (stackView.views[2] as! NSTextField).isEnabled = false
                (stackView.views[3] as! NSTextField).isEnabled = false
            }
        }
        
    }
    
    func saveFrame() {
        let row = keyframesTableView.selectedRow
        guard row >= 0 && row < keyFrames.count else {
            return
        }
        let keyFrame = keyFrames[row]
        keyFrame.time = timeField.doubleValue
        
        for (pivotIndex, stack) in attributesStackView.views.enumerated() {
            let stackView = stack as! NSStackView
            keyFrame.pivots[pivotIndex].x = (stackView.views[1] as! NSTextField).floatValue
            keyFrame.pivots[pivotIndex].y = (stackView.views[2] as! NSTextField).floatValue
            keyFrame.pivots[pivotIndex].z = (stackView.views[3] as! NSTextField).floatValue
        }
        
    }
    
    @IBAction func addFrame(_ sender: Any) {
        saveFrame()
        keyFrames.append(HGLKeyframe())
        reloadUI()
    }
    
    @IBAction func removeFrame(_ sender: Any) {
        if keyframesTableView.selectedRow >= 0 {
            keyFrames.remove(at: keyframesTableView.selectedRow)
        }
        reloadUI()
    }
    
    @IBAction func reloadHuman(_ sender: Any) {
        saveFrame()
        guard keyframesTableView.selectedRow >= 0 else {
            return
        }
        let keyFrame = keyFrames[keyframesTableView.selectedRow]
        for (index, node) in HGLKeyframe.pivotsNodes.enumerated() {
            let angles = keyFrame.pivots[index]
            node.eulerAngles = SCNVector3(angles)
        }
    }
    
    @IBAction func playAnimation(_ sender: Any) {
        
        saveFrame()
        guard keyFrames.count > 0 else {
            return
        }
        
        var actionsSequences = [[SCNAction]](repeating: [], count: HGLKeyframe.pivotsNames.count)
        
        var previousTime: TimeInterval = 0
        
        for keyFrame in keyFrames {
            let deltaTime = keyFrame.time - previousTime
            previousTime = keyFrame.time
            for index in 0..<HGLKeyframe.pivotsNames.count {
                let angles = keyFrame.pivots[index]
                let action = SCNAction.rotateTo(x: CGFloat(angles.x),
                                                y: CGFloat(angles.y),
                                                z: CGFloat(angles.z),
                                                duration: deltaTime)
                actionsSequences[index].append(action)
            }
        }
        
        for (index, node) in HGLKeyframe.pivotsNodes.enumerated() {
            let sequence = SCNAction.sequence(actionsSequences[index])
            node.runAction(SCNAction.repeatForever(sequence),
                           forKey: "animation")
        }
        
    }
    
    @IBAction func stopAnimation(_ sender: Any) {
        
        for node in HGLKeyframe.pivotsNodes {
            node.removeAction(forKey: "animation")
        }
        
    }
    
    func saveKeyframes() -> String {
        let vectorNames = ["x", "y", "z"]
        
        var content = ""
        for keyFrame in keyFrames {
            for (pivotIndex, pivot) in keyFrame.pivots.enumerated() {
                for (i, value) in pivot.enumerated() {
                    if value != 0 {
                        let name = HGLKeyframe.nameOf(pivotAt: pivotIndex)!
                        content += "\(name) \(vectorNames[i]) \(value)\n"
                    }
                }
            }
            content += "time \(keyFrame.time)\n\n"
        }
        return content
    }
    
    @IBAction func saveAnimation(_ sender: Any) {
        
        saveFrame()
        
        let filePicker = NSSavePanel()
        filePicker.nameFieldStringValue = "animation"
        filePicker.allowedFileTypes = ["hgl"]
        
        filePicker.runModal()
        
        if let url = filePicker.url {
            let content = saveKeyframes()
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch let error {
                let alert = NSAlert()
                alert.messageText = "Could not save to file \(url): \(error.localizedDescription)"
                alert.runModal()
            }
        }
    }
    
    func parse(lines: [Substring]) {
        
        let vectorIndex = ["x": 0, "y": 1, "z": 2]
        
        keyFrames = []
        var keyFrame = HGLKeyframe()
        for line in lines {
            print("parsing line:\(line)")
            let words = line.split(separator: " ")
            if words.count >= 2 && words[0] == "time" {
                keyFrame.time = Double(words[1]) ?? 0
                print("append frame at \(keyFrame.time)")
                keyFrames.append(keyFrame)
                keyFrame = HGLKeyframe()
            } else if words.count >= 3 {
                if let index = HGLKeyframe.indexOf(pivotNamed: String(words[0])),
                    let vi = vectorIndex[String(words[1])],
                    let value = Float(words[2]) {
                    keyFrame.pivots[index][vi] = value
                    print("set value \(value) to pivot \(index).\(vi)")
                } else {
                    print("error :/")
                }
            } else {
                print("nothing")
            }
        }
        
    }
    
    @IBAction func openAnimation(_ sender: Any) {
        let filePicker = NSOpenPanel()
        filePicker.allowsMultipleSelection = false
        filePicker.canChooseDirectories = false
        filePicker.canChooseFiles = true
        
        filePicker.runModal()
        
        if let url = filePicker.url {
            do {
                let fileContent = try String(contentsOf: url)
                parse(lines: fileContent.split(separator: "\n"))
            } catch let error {
                let alert = NSAlert()
                alert.messageText = "Could not open file \(url): \(error.localizedDescription)"
                alert.runModal()
            }
        }
        
        reloadUI()
    }
    
}

extension ViewController {
    
    override func mouseDragged(with event: NSEvent) {
        cameraPivot.eulerAngles.y -= event.deltaX * 0.005
        print("mouse dragg")
    }
    
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keyFrames.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let title = tableColumn?.title else {
            return nil
        }
        if title == "time" {
            return "\(keyFrames[row].time)"
        } else if let pivotIndex = HGLKeyframe.indexOf(pivotNamed: title) {
            return "\(keyFrames[row].pivots[pivotIndex])"
        }
        return nil
    }
    
    func selectionShouldChange(in tableView: NSTableView) -> Bool {
        
        saveFrame()
        
        return true
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        
        reloadUI()
        
        reloadHuman(self)
        
    }
    
    
}

