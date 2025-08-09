//
//  dates.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 27.09.2023.
//

import Foundation

let months: [String] = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
]

/**
 Define application / user date format
 */
let defaultDateFormat = "yyyy-MM-dd"
let possibleDateFormatDecoders: [String] = [
    "yyyy-MM-dd",
    "dd/MM/yyyy",
    "yyyy-MM-dd'T'HH:mm:ssZ",
    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
]
/**
 Define format that backend use
 */
let defaultBackendDateFormat = "yyyy-MM-dd"
let kycDateFormat = "dd/MM/yyyy"
