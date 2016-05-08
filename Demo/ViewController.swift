import UIKit
import FaceTracker

class ViewController: UIViewController, FaceTrackerViewControllerDelegate {
    
    var mustacheView = UIImageView()
    var faceTrackerViewController: FaceTrackerViewController?
    var pointViews = [UIView]()
    var isPaused = true
    var timer: NSTimer!
    var overlayViews = [String: [UIView]]()
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var optionsButton: UIButton!
    @IBOutlet var faceTrackerContainerView: UIView!
    @IBOutlet weak var mustacheBar: UIStackView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.insertSubview(mustacheView, aboveSubview: faceTrackerContainerView)
        mustacheView.image = UIImage(named: "mustache")
    
        timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)

        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        faceTrackerViewController!.startTracking { () -> Void in
            self.activityIndicator.stopAnimating()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources tstash can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "embedFaceTrackerViewController") {
            faceTrackerViewController = segue.destinationViewController as? FaceTrackerViewController
            faceTrackerViewController!.delegate = self
        }
    }
    
    @IBAction func optionsButtonPressed(sender: UIButton) {
        let alert = UIAlertController()
        alert.popoverPresentationController?.sourceView = optionsButton
        
        alert.addAction(UIAlertAction(title: "Swap Camera", style: .Default, handler: { (action) -> Void in
            self.faceTrackerViewController!.swapCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateViewForFeature(feature: String, index: Int, point: CGPoint, bgColor: UIColor) {
        
        let frame = CGRectMake(point.x-2, point.y-2, 4.0, 4.0)
        
        if self.overlayViews[feature] == nil {
            self.overlayViews[feature] = [UIView]()
        }
        
        if index < self.overlayViews[feature]!.count {
            self.overlayViews[feature]![index].frame = frame
            self.overlayViews[feature]![index].hidden = false
            self.overlayViews[feature]![index].backgroundColor = bgColor
        } else {
            let newView = UIView(frame: frame)
            newView.backgroundColor = bgColor
            newView.hidden = false
            self.view.addSubview(newView)
            self.overlayViews[feature]! += [newView]
        }
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform)
        
        var position = view.layer.position
        
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
        
    }
    
    func faceTrackerDidUpdate(points: FacePoints?) {
        
        if let points = points {
            // Allocate some views for the points if needed
            if (pointViews.count == 0) {
                let numPoints = points.getTotalNumberOFPoints()
                for _ in 0...numPoints {
                  
                    let view = UIView()
                    view.backgroundColor = UIColor.clearColor()
                    self.view.addSubview(view)
                    
                    pointViews.append(view)
                }
            }
            
            // Set frame for each point view
            points.enumeratePoints({ (point, index) -> Void in
                let pointView = self.pointViews[index]
                let pointSize: CGFloat = 2
                
                pointView.hidden = false
                pointView.frame = CGRectIntegral(CGRectMake(point.x - pointSize / 2, point.y - pointSize / 2, pointSize, pointSize))
                pointView.layer.cornerRadius = pointView.frame.width / 2
            })
            
            for (index, point) in points.rightEye.enumerate() {
                self.updateViewForFeature("rightEye", index: index, point: point, bgColor: UIColor.clearColor())
            }
            
            
            // Compute the mustache frame :{
            let eyeCornerDist = sqrt(pow(points.leftEye[0].x - points.rightEye[5].x, 2) + pow(points.leftEye[0].y - points.rightEye[5].y, 2))
            let eyeToEyeCenter = CGPointMake((points.leftEye[0].x + points.rightEye[5].x) / 2, (points.leftEye[0].y + points.rightEye[5].y) / 2)
            
            let stashWidth = eyeCornerDist
            let stashHeight = (mustacheView.image!.size.height / mustacheView.image!.size.width) * stashWidth
            
            mustacheView.transform = CGAffineTransformIdentity
            
            if( mustacheView.image == UIImage(named: "mustache_pipe") ){
                mustacheView.frame = CGRectMake((eyeToEyeCenter.x - stashWidth / 2) + 10, eyeToEyeCenter.y + 0.5
                    * stashHeight, stashWidth, stashHeight)

            }else{
                mustacheView.frame = CGRectMake( eyeToEyeCenter.x - stashWidth / 2, eyeToEyeCenter.y + 0.09 * stashHeight, stashWidth, stashHeight)
            }
            mustacheView.hidden = false
            
            setAnchorPoint(CGPointMake(1.0, 1.0), forView: mustacheView)
            let angle = atan2(points.rightEye[0].y - points.leftEye[0].y, points.rightEye[0].x - points.leftEye[0].x)
            mustacheView.transform = CGAffineTransformMakeRotation(angle)
            
            
        }
        else {
            mustacheView.hidden = true
            
            for view in pointViews {
                view.hidden = true
            }
        }
    }
    
    func runTimedCode() {
        if isPaused{
            if( mustacheView.image == UIImage(named: "mustache") ){
                mustacheView.image = UIImage(named: "ungrommed")
            }
            else if( mustacheView.image == UIImage(named: "ungrommed") ){
                mustacheView.image = UIImage(named: "walrus")
            }
            else if( mustacheView.image == UIImage(named: "walrus") ){
                mustacheView.image = UIImage(named: "pencil")
            }
            else if( mustacheView.image == UIImage(named: "pencil") ){
                mustacheView.image = UIImage(named: "mustache_pipe")
            }
            else if( mustacheView.image == UIImage(named: "mustache_pipe") ){
                mustacheView.image = UIImage(named: "mustache")
            }
        }else{
            timer.invalidate()
            isPaused = true
        }
    }
    
    // event handlers to change image
    @IBAction func mustacheButton(sender: AnyObject) {
        mustacheView.image = UIImage(named: "mustache")
        if isPaused{
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
            isPaused = false
        } else {
            timer.invalidate()
            isPaused = true
        }
    }
    
    @IBAction func ungrommedButton(sender: AnyObject) {
        mustacheView.image = UIImage(named: "ungrommed")
        if isPaused{
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
            isPaused = false
        } else {
            timer.invalidate()
            isPaused = true
        }
    }
    
    @IBAction func walrusButton(sender: AnyObject) {
        mustacheView.image = UIImage(named: "walrus")
        if isPaused{
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
            isPaused = false
        } else {
            timer.invalidate()
            isPaused = true
        }
    }
    
    @IBAction func pencilButton(sender: AnyObject) {
        mustacheView.image = UIImage(named: "pencil")
        if isPaused{
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
            isPaused = false
        } else {
            timer.invalidate()
            isPaused = true
        }
    }
    
    @IBAction func mustachePipeButton(sender: AnyObject) {
        mustacheView.image = UIImage(named: "mustache_pipe")
        if isPaused{
            timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
            isPaused = false
        } else {
            timer.invalidate()
            isPaused = true
        }
    }
    

//    @IBAction func useCamera(sender: AnyObject) {
//
//        photoTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(takePhoto), userInfo: nil, repeats: false)
//        // hide ui elements
//        optionsButton.hidden = true
//        takePhotoButton.hidden = true
//        mustacheBar.hidden = true
    var photoTimer: NSTimer!
    @IBAction func useCamera(sender: AnyObject) {
        photoTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(takePhoto), userInfo: nil, repeats: false)
        // hide ui elements
        optionsButton.hidden = true
        takePhotoButton.hidden = true
        mustacheBar.hidden = true
    }

    
    func takePhoto(){
        
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        
        // show ui elements
        optionsButton.hidden = false
        takePhotoButton.hidden = false
        mustacheBar.hidden = false
        
    }
    
}

