//
//  Platform.swift
//  KardioKart
//
//  Created by Bobby Ren on 8/3/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

// Elsewhere...
/*
if Platform.isSimulator {
    // Do one thing
}
else {
    // Do the other
}*/