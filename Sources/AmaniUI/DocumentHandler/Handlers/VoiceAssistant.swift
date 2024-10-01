//
//  File.swift
//  
//
//  Created by Y. Yılmaz Erdoğmuş on 29.09.2024.
//

import Foundation
import AVKit

class VoiceAssistant{
  static var shared = VoiceAssistant()
  var synthesizer = AVSpeechSynthesizer()
  
  func speakManager(text: String, language: String){
    let utterance = AVSpeechUtterance(string: text)
    let voice = AVSpeechSynthesisVoice(language: language)
    utterance.voice = voice
    utterance.rate = 0.5
    utterance.pitchMultiplier = 0.9
    utterance.postUtteranceDelay = 0.1
    utterance.volume = 0.9
    
    self.synthesizer.speak(utterance)
  }
}
