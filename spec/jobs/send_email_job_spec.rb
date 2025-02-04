require "rails_helper"

RSpec.describe SendEmailJob, type: :job do
  let(:user)   {create(:user)}
  let(:status) {:borrowing}

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "enqueues the job" do
    expect {
      described_class.perform_later(user.id, status)
    }.to have_enqueued_job(SendEmailJob).with(user.id, status).on_queue("mailers")
  end

  it "performs the job and sends an email" do
    mailer_double = instance_double(ActionMailer::MessageDelivery)
    allow(UserMailer).to receive(:request_status_changed).with(user, status).and_return(mailer_double)
    allow(mailer_double).to receive(:deliver_later)

    described_class.perform_now(user.id, status)

    expect(UserMailer).to have_received(:request_status_changed).with(user, status)
    expect(mailer_double).to have_received(:deliver_later)
  end
end
