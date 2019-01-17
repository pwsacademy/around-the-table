/**
 Form for sending a message.
 */
struct MessageForm: Codable {

    let topic: Int?
    let sender: Int
    let recipient: Int
    let text: String
}
