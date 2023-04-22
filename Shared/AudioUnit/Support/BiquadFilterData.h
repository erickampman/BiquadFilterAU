//
//  BiquadFilterData.h
//  BiquadFilter
//
//  Created by Eric Kampman on 1/29/23.
//  Copyright © 2023 UnlikeleyWare. All rights reserved.
//

#ifndef BiquadFilterData_h
#define BiquadFilterData_h

typedef NS_ENUM(NSInteger, PARAM_ITEM_FILTER_TYPE) {
	PARAM_ITEM_FILTER_TYPE_PASSTHROUGH,
	PARAM_ITEM_FILTER_TYPE_LOWPASS,
	PARAM_ITEM_FILTER_TYPE_HIGHPASS,
	PARAM_ITEM_FILTER_TYPE_BANDPASS,
	PARAM_ITEM_FILTER_TYPE_NOTCH,
	PARAM_ITEM_FILTER_TYPE_PEAKINGEQ,
};

#endif /* BiquadFilterData_h */
