class LogNotifier
  def notify(context, message)
    context.logger.info message
  end
end
