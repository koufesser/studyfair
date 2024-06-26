# frozen_string_literal: true

class Gateway::Telegram::WebhooksController < Gateway::Telegram::ApplicationController
  include Gateway::Telegram::Rescueable

  before_action do
    next if input.chat_object.present?

    head :unprocessable_entity
  end

  def notify
    within_transaction do
      within_lock do
        dispatch_command
      end
    end

    head :ok
  end

  private

    def within_transaction(&)
      ApplicationRecord.transaction(&)
    end

    def within_lock(&)
      if telegram_chat
        ApplicationRecord.with_advisory_lock([self.class.name, telegram_chat.id], transaction: true, &)
      else
        yield
      end
    end

    def dispatch_command
      service_result = TelegramForm::ProcessRequestService.call(
        telegram_form:, telegram_chat:, input:
      )

      if service_result.success?
        reply_with(event_response(service_result.event, service_result.context))
      else
        reply_with(event_response(service_result.reason, {}))
      end
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def event_response(event, context)
      # NOTE: dirty!
      return context.fetch(:preview) if event == :succeeded_preview

      i18n_key = event.dup

      Rails.logger.info(event)
      Rails.logger.info(context)

      context = if event == :created_upload # FIXME: Align naming with current implementation.
        { filename: context.fetch(:upload).filename }
      elsif event == :updated_to_course_provided_stage
        assignments = context.fetch(:assignments).pluck(:title).join("\n")
        last_telegram_form = telegram_form.telegram_chat.telegram_forms.completed.order(updated_at: :desc).take
        i18n_key = if last_telegram_form
          "#{event}.with_existing_submission"
        else
          "#{event}.default"
        end
        { assignments: }
      elsif event == :telegram_chat_group_provided
        courses = Course.active.joins(:groups).where(groups: { title: telegram_chat.reload.group }).pluck(:title).join("\n")
        i18n_key = :courses_not_found if courses.blank?

        { courses: }
      elsif event == :updated_to_uploads_provided_stage
        assignments = context.fetch(:assignments).pluck(:title).map.with_index(1) { |val, index| "#{index}. #{val}" }.join("\n")
        { assignments: }
      elsif event == :github_url_provided
        { url: context.fetch(:url) }
      else
        {}
      end

      I18n.with_locale(:ru) { t i18n_key, context }
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def t(key, context = {})
      I18n.t(key, **context, scope: "controllers.gateway.telegram.webhooks.messages")
    end

    def telegram_form
      telegram_chat&.telegram_forms&.incompleted&.take
    end

    def telegram_chat
      return @telegram_chat if defined?(@telegram_chat)

      @telegram_chat = TelegramChat
        .find_by(external_identifier: input.chat_id)
    end

    def reply_with(message) = api_client.send_message(chat_id: input.chat_id, text: message)

    def input = @input ||= TelegramForm::ParseInputService.call(params: params.to_unsafe_h).input

    def api_client = Telegram::Bot::Client.default
end
