import UIKit

import CoreImage
import Foundation

extension CIImage {
    /// Applies an AdaptiveThresholding filter to the image, which enhances the image and makes it completely gray scale
    func applyingAdaptiveThreshold() -> UIImage? {
        guard let colorKernel = CIColorKernel(source:
            """
            kernel vec4 color(__sample pixel, float inputEdgeO, float inputEdge1)
            {
                float luma = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
                float threshold = smoothstep(inputEdgeO, inputEdge1, luma);
                return vec4(threshold, threshold, threshold, 1.0);
            }
            """
            ) else { return nil }
        
        let firstInputEdge = 0.25
        let secondInputEdge = 0.75
        
        let arguments: [Any] = [self, firstInputEdge, secondInputEdge]
        
        guard let enhancedCIImage = colorKernel.apply(extent: self.extent, arguments: arguments) else { return nil }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(enhancedCIImage, forKey: kCIInputImageKey)
        filter?.setValue(1, forKey: "inputSaturation")
        filter?.setValue(0, forKey: "inputBrightness")
        filter?.setValue(1, forKey: "inputContrast")
        let filteredImage = filter?.outputImage
        
        if let cgImage = CIContext(options: nil).createCGImage(filteredImage!, from: filteredImage!.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

var image = UIImage(named: "ok.jpg")
var enhancedImage = CIImage(image: image!)!.applyingAdaptiveThreshold()
