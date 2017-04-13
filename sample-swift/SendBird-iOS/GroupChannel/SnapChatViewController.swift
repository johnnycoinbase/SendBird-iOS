import UIKit
import SendBirdSDK

class SnapChatViewController: GroupChannelChattingViewController, SBDChannelDelegate {
	
    override func viewDidLoad() {
        super.viewDidLoad()

        SBDMain.add(self as SBDChannelDelegate, identifier: self.delegateIdentifier)
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(deleteMessage(notification:)),
		                                       name: NSNotification.Name(rawValue: Constants.deleteMessage),
		                                       object: nil)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		NotificationCenter.default.removeObserver(self)
	}
	
	func deleteMessage(notification: Notification) {
		guard let message = notification.userInfo?["message"] as? SBDBaseMessage else {
			return
		}
		
		groupChannel.delete(message) { (error) in
			NSLog("message deleted")
		}
	}
	
	let deletionTime: TimeInterval = 10

	// MARK: SBDChannelDelegate
	func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
		if sender == self.groupChannel {
			self.groupChannel.markAsRead()
			
			self.chattingView.messages.append(message)
			self.chattingView.chattingTableView.reloadData()
			DispatchQueue.main.async {
				self.chattingView.scrollToBottom(animated: true, force: false)
			}
			
			// To get the last message, use sender.lastMessage
			chattingView.startDeletionCountdown(timeInterval: deletionTime)
		}
	}
	
	func channelDidUpdateReadReceipt(_ sender: SBDGroupChannel) {
		if sender == self.groupChannel {
			DispatchQueue.main.async {
				self.chattingView.chattingTableView.reloadData()
			}
			
			guard let lastMessage = sender.lastMessage else {
				return
			}
			
			// Start simultaneous timer for message deletion from senders end.
			Timer.scheduledTimer(withTimeInterval: deletionTime, repeats: false, block: { (timer) in
				sender.delete(lastMessage, completionHandler: { (error) in
					NSLog("message deleted")
				})
			})
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
