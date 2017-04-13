import UIKit
import SendBirdSDK

class SnapChatViewController: GroupChannelChattingViewController, SBDChannelDelegate {
	
    override func viewDidLoad() {
        super.viewDidLoad()

        SBDMain.add(self as SBDChannelDelegate, identifier: self.delegateIdentifier)
    }
	
	// JC TODO: Start observing global notification to delete the message.
	// This should happen after the countdown expires.
	
	// MARK: SBDChannelDelegate
	func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
		if sender == self.groupChannel {
			self.groupChannel.markAsRead()
			
			self.chattingView.messages.append(message)
			self.chattingView.chattingTableView.reloadData()
			DispatchQueue.main.async {
				self.chattingView.scrollToBottom(animated: true, force: false)
			}
			
			// JC TODO: Message read by recipient, start timer to delete message
		}
	}
	
	func channelDidUpdateReadReceipt(_ sender: SBDGroupChannel) {
		if sender == self.groupChannel {
			DispatchQueue.main.async {
				self.chattingView.chattingTableView.reloadData()
			}
			
			// JC TODO: Start a simultaneous timer as above for message deletion from the senders end.
			//	The reason is because there isn't a backend service to sync the deletion so 
			//	timers have to be started on the client from both ends (sender and receiver
		}
	}
	
	func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
		if sender == self.groupChannel {
			if sender.getTypingMembers()?.count == 0 {
				self.chattingView.endTypingIndicator()
			}
			else {
				if sender.getTypingMembers()?.count == 1 {
					self.chattingView.startTypingIndicator(text: String(format: Bundle.sbLocalizedStringForKey(key: "TypingMessageSingular"), (sender.getTypingMembers()?[0].nickname)!))
				}
				else {
					self.chattingView.startTypingIndicator(text: Bundle.sbLocalizedStringForKey(key: "TypingMessagePlural"))
				}
			}
		}
	}
	
	func channelWasChanged(_ sender: SBDBaseChannel) {
		if sender == self.groupChannel {
			DispatchQueue.main.async {
				self.navItem.title = String(format: Bundle.sbLocalizedStringForKey(key: "GroupChannelTitle"), self.groupChannel.memberCount)
			}
		}
	}
	
	func channelWasDeleted(_ channelUrl: String, channelType: SBDChannelType) {
		let vc = UIAlertController(title: Bundle.sbLocalizedStringForKey(key: "ChannelDeletedTitle"), message: Bundle.sbLocalizedStringForKey(key: "ChannelDeletedMessage"), preferredStyle: UIAlertControllerStyle.alert)
		let closeAction = UIAlertAction(title: Bundle.sbLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel) { (action) in
			self.close()
		}
		vc.addAction(closeAction)
		DispatchQueue.main.async {
			self.present(vc, animated: true, completion: nil)
		}
	}
	
	func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
		if sender == self.groupChannel {
			for message in self.chattingView.messages {
				if message.messageId == messageId {
					self.chattingView.messages.remove(at: self.chattingView.messages.index(of: message)!)
					DispatchQueue.main.async {
						self.chattingView.chattingTableView.reloadData()
					}
					break
				}
			}
		}
	}

}
