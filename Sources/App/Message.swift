import Elementary
import ElementaryHTMX

struct Message: HTML {
  
  var model: MessageModel
  
  var content: some HTML {
    article(
      .class("chat-row")
    ) {
      span(.class("sender")) { model.sender }
      span(.class("message")) { model.text }
      span(.class("date")) { model.dateFormatted }
    }
  }
}
