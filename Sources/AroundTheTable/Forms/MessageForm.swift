/**
 Form for sending a message.
 */
struct MessageForm: Codable {

    let topic: Int
    let sender: String
    let recipient: String
    let text: String
}
