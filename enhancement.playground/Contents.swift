import UIKit

import CoreImage
import Foundation

extension CIImage {
    /// Applies an AdaptiveThresholding filter to the image, which enhances the image and makes it completely gray scale
    func applyingAdaptiveThreshold() -> UIImage? {
        let dilateSize: CGFloat = 4
        guard let dilateKernel = CIKernel(source:
            """
            kernel vec4 blur (sampler image, float dilateSize) {
                vec2 current = destCoord();

                vec4 c = sample(image, samplerTransform(image, current));
                for (float i = -dilateSize; i <= dilateSize; i++)
                    for (float j = -dilateSize; j <= dilateSize; j++)
                        c = max(c, sample(image, samplerTransform(image, current + vec2(i, j))));

                return c;
            }
            """
            ) else { return nil }
        
        guard let dilatedImage = dilateKernel.apply(extent: self.extent.insetBy(dx: -dilateSize, dy: -dilateSize), roiCallback: { (index: Int32, rect: CGRect) -> CGRect in
            return rect.insetBy(dx: -dilateSize, dy: -dilateSize)
        }, arguments: [self, CGFloat(dilateSize)]) else { return nil }
        
        let medianImage = dilatedImage.applyingFilter("CIMedianFilter")
        
        guard let absdiffKernel = CIKernel(source:
            """
            kernel vec4 blur (sampler image, sampler background) {
                vec2 current = destCoord();

                vec4 c = sample(image, samplerTransform(image, current));
                vec4 b = sample(background, samplerTransform(background, current));

                return vec4(1.0, 1.0, 1.0, 1.0) - abs(c - b);
            }
            """
            ) else { return nil }

        guard let absdiffImage = absdiffKernel.apply(extent: self.extent, roiCallback: { (index: Int32, rect: CGRect) -> CGRect in
            return rect
        }, arguments: [self, medianImage]) else { return nil }
        
        let _c = CIContext(options: nil).createCGImage(absdiffImage, from: absdiffImage.extent)!

        let firstInputEdge = 0.87
        let secondInputEdge = 0.95
        guard let thresholdKernel = CIColorKernel(source:
            """
            kernel vec4 color(__sample pixel, float inputEdgeO, float inputEdge1)
            {
                float luma = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
                float threshold = smoothstep(inputEdgeO, inputEdge1, luma);
                return vec4(threshold, threshold, threshold, 1.0);
            }
            """
            ) else { return nil }
        
        guard let thresholdImage = thresholdKernel.apply(extent: absdiffImage.extent, arguments: [absdiffImage, firstInputEdge, secondInputEdge]) else { return nil }
        
        let _d = CIContext(options: nil).createCGImage(thresholdImage, from: thresholdImage.extent)!
        
        let filteredImage = thresholdImage.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1, kCIInputBrightnessKey: 0, kCIInputContrastKey: 1])
        
        if let cgImage = CIContext(options: nil).createCGImage(filteredImage, from: filteredImage.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

var ok_image = UIImage(named: "ok_cropped.jpg")
var ok_enhancedImage = CIImage(image: ok_image!)!.applyingAdaptiveThreshold()

var issue_image = UIImage(named: "issue_cropped.jpg")
var issue_enhancedImage = CIImage(image: issue_image!)!.applyingAdaptiveThreshold()
