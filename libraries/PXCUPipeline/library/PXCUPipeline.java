/*******************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or nondisclosure
agreement with Intel Corporation and may not be copied or disclosed except in
accordance with the terms of that agreement
Copyright(c) 2012-2013 Intel Corporation. All Rights Reserved.

*******************************************************************************/
package intel.pcsdk;

import intel.pcsdk.*;
import processing.core.*;
import java.nio.*; 

public class PXCUPipeline extends PXCUPipelineJNI {
	private PApplet parent;

	public PXCUPipeline(PApplet parent) {    
		super();
		this.parent = parent;
		parent.registerDispose(this);
	}  

	public boolean QueryRGB(PImage rgbImage) {
		if (rgbImage==null) return false;
		rgbImage.loadPixels();
		boolean sts=QueryRGB(rgbImage.pixels);
		rgbImage.updatePixels();
		return sts;
	}
  
	public boolean QueryLabelMapAsImage(PImage data) {
		if (data==null) return false;
		byte[] labelMap=new byte[data.width*data.height];
		int[] labels=new int[3];
		if (!QueryLabelMap(labelMap,labels)) return false;
		data.loadPixels();
		for (int i=0;i<labelMap.length;i++)
			data.pixels[i]=(0xff<<24)+(labelMap[i]<<16)+(labelMap[i]<<8)+(labelMap[i]);
		data.updatePixels();
		return true;
	}
}
