# frozen_string_literal: true

describe Gateway::Telegram::WebhooksController do
  describe "#notify" do
    def perform(params)
      post :notify, params:
    end

    let(:telegram_client_double) { instance_double(Telegram::Bot::Client, send_message: true) }

    let(:chat_id_param) { 983_390_842 }
    let(:message_text_param) { nil }
    let(:message_document_param) { nil }

    let(:params) do
      {
        update_id: 571_662_017,
        message: {
          message_id: 175,
          from: {
            id: 983_390_842,
            is_bot: false,
            first_name: "Yaroslav",
            username: "viralpraxis",
            language_code: "en"
          },
          chat: {
            id: 983_390_842,
            first_name: "Yaroslav",
            username: "viralpraxis",
            type: "private"
          },
          date: 1_697_742_886,
          document: message_document_param,
          text: message_text_param,
          entities: [{ "offset" => 0, "length" => 6, "type" => "bot_command" }]
        },
        webhook: {
          update_id: 571_662_017,
          message: {
            message_id: 175,
            from: {
              id: 983_390_842,
              is_bot: false,
              first_name: "Yaroslav",
              username: "viralpraxis",
              language_code: "en"
            },
            chat: {
              id: 983_390_842,
              first_name: "Yaroslav",
              username: "viralpraxis",
              type: "private"
            },
            date: 1_697_742_886,
            text: message_text_param,
            entities: [{ "offset" => 0, "length" => 6, "type" => "bot_command" }]
          }
        }
      }
    end

    before do
      allow(Telegram::Bot::Client).to receive(:new).and_return(telegram_client_double)
    end

    shared_examples "it does not persist any instances of `TelegramForm` model" do
      specify do
        expect { perform(params) }.not_to change(TelegramForm, :count)
      end
    end

    shared_examples "it responds to telegram chat" do |text:|
      specify do
        perform(params)

        expect(telegram_client_double).to have_received(:send_message).with(
          chat_id: chat_id_param.to_s,
          text:
        ).once
      end
    end

    context "with invalid request" do
      specify do
        perform({})

        expect(telegram_client_double).not_to have_received(:send_message)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without telegram form" do
      let(:message_text_param) { "start" }
      let(:course) { create(:course, :active, title: "advanced-haskell") }

      before do
        create(:assignment, course:, title: "task-foo")
      end

      specify do
        perform(params)

        expect(response).to have_http_status(:ok)
      end

      specify do
        perform(params)

        expect(TelegramForm).to be_none
        expect(TelegramChat).to be_none
      end

      it_behaves_like "it responds to telegram chat",
        text: "Некорректная команда"
    end

    # context "with telegram form on `created` stage" do
    #   let(:telegram_chat) { create(:telegram_chat)}
    #   let!(:telegram_form) { create(:telegram_form, :created) }
    #   let(:course) { create(:course, :active, title: "advanced-haskell") }

    #   before do
    #     create(:assignment, course:, title: "task-foo")
    #     create(:assignment, course:, title: "task-bar")
    #   end

    #   context "with exact course title match" do
    #     let(:message_text_param) { course.title }

    #     it_behaves_like "it does not persist any instances of `TelegramForm` model"

    #     it_behaves_like "it responds to telegram chat",
    #       text: "Введите свою группу"

    #     specify do
    #       perform(params)

    #       expect(response).to have_http_status(:ok)
    #     end
    #   end

    #   context "with course title case mismatch" do
    #     let(:message_text_param) { course.title.upcase }

    #     it_behaves_like "it does not persist any instances of `TelegramForm` model"

    #     it_behaves_like "it responds to telegram chat",
    #       text: "Введите свою группу"

    #     specify do
    #       perform(params)

    #       expect(response).to have_http_status(:ok)
    #     end
    #   end
    # end

    # context "with telegram form on `telegram_chat_populated` stage" do
    # end

    context "with telegram form on `course_provided` stage" do
      let!(:telegram_form) { create(:telegram_form, :course_provided, course:, telegram_chat:) }
      let(:course) { create(:course, :active, title: "advanced-haskell") }
      let(:assignment) { create(:assignment, course:) }
      let(:telegram_chat) { create(:telegram_chat, :with_status_group_provided, external_identifier: chat_id_param) }

      let(:message_text_param) { assignment.title }

      it_behaves_like "it does not persist any instances of `TelegramForm` model"

      it_behaves_like "it responds to telegram chat",
        text: "Приложите решение одним или несколькими файлами. Затем введите команду `/submit`"

      specify do
        perform(params)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with telegram form on `assignment_provided` stage" do
      let!(:telegram_form) do
        create(
          :telegram_form,
          :assignment_provided,
          course:,
          assignment:,
          telegram_chat:
        )
      end
      let(:course) { create(:course, title: "advanced-haskell") }
      let(:assignment) { create(:assignment) }
      let(:telegram_chat) { create(:telegram_chat, :with_status_group_provided, external_identifier: chat_id_param) }

      let(:message_text_param) { nil }
      let(:message_document_param) do
        {
          file_name: "Аленова_София_01.py",
          mime_type: "text/x-python",
          file_id: "BQACAgIAAxkBAAPAZTKE2NJ5njiw3SbtNWT7nRevMqgAArEyAAIGrJlJ_Rd7mB_MgmkwBA",
          file_unique_id: "AgADsTIAAgasmUk",
          file_size: 2035
        }
      end

      it_behaves_like "it does not persist any instances of `TelegramForm` model"

      it_behaves_like "it responds to telegram chat",
        text: "Файл принят (Аленова_София_01.py)"

      specify do
        perform(params)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with `/start` command" do
      let(:telegram_form) { nil }

      let(:message_text_param) { "/start" }

      before do
        create(:course, :active, title: "haskell")
        create(:course, :active, title: "python")
      end

      it_behaves_like "it responds to telegram chat",
        text: "Введите свое ФИО"

      specify do
        perform(params)

        expect(response).to have_http_status(:ok)
        expect(TelegramForm.sole).to be_created
      end

      it "persists an instance of `TelegramForm` model" do
        expect { perform(params) }.to change(TelegramForm, :count).from(0).to(1)
      end
    end

    context "with `/preview` command" do
      let!(:telegram_form) do
        create(
          :telegram_form,
          :assignment_provided,
          course:,
          assignment:,
          submission:,
          telegram_chat:
        )
      end
      let(:course) { create(:course, title: "advanced-haskell") }
      let(:assignment) { create(:assignment, title: "assignment-1") }
      let(:submission) { create(:submission, :files_group, assignment:) }
      let(:telegram_chat) { create(:telegram_chat, :with_status_group_provided, external_identifier: chat_id_param) }

      let(:message_text_param) { "/preview" }

      let(:expected_response) do
        <<~TXT.chomp
          Курс: advanced-haskell
          Задание: #{assignment.title}
          Автор: #{telegram_chat.name}
          Группа: #{telegram_chat.group}
          Файлов: 0
        TXT
      end

      before do
        a1 = create(:assignment, title: "assignment-2", course:)
        a2 = create(:assignment, title: "assignment-3", course:)

        s1 = create(:submission, :files_group, assignment: a1)
        s2 = create(:submission, :files_group, assignment: a2)

        create(:telegram_form, :uploads_provided, course:, assignment: a1, submission: s1, telegram_chat:)
        create(:telegram_form, :uploads_provided, course:, assignment: a2, submission: s2, telegram_chat:)
      end

      it_behaves_like "it does not persist any instances of `TelegramForm` model"

      specify do
        perform(params)

        expect(telegram_client_double).to have_received(:send_message).with(
          chat_id: chat_id_param.to_s,
          text: expected_response
        ).once
      end
    end

    context "with `/submit` command" do
      let!(:telegram_form) do
        create(
          :telegram_form,
          :assignment_provided,
          course:,
          assignment:,
          submission:,
          telegram_chat:
        )
      end
      let(:course) { create(:course, title: "advanced-haskell") }
      let(:assignment) { create(:assignment) }
      let(:submission) { create(:submission, :files_group, assignment:) }
      let(:telegram_chat) { create(:telegram_chat, :with_status_group_provided, external_identifier: chat_id_param) }

      let(:message_text_param) { "/submit" }

      let(:expected_response) do
        "Ваше решение зарегистрировано\n\nСдано:\n\n1. #{assignment.title}"
      end

      it_behaves_like "it does not persist any instances of `TelegramForm` model"

      specify do
        perform(params)

        expect(telegram_client_double).to have_received(:send_message).with(
          chat_id: chat_id_param.to_s, text: expected_response
        ).once
        expect(TelegramForm.sole).to have_attributes(
          stage: "uploads_provided"
        )
      end

      specify do
        expect { perform(params) }.to have_enqueued_job(Assignment::CreateJob)
      end
    end
  end
end