require 'spec_helper'

include ActionTracker::Helpers::Render

describe ActionTracker::Concerns::Tracker do
  before do
    @event_list = []
    @fake_session = {}

    allow_any_instance_of(ApplicationTestController).to receive(:session).and_return(@fake_session)
    allow_any_instance_of(described_class).to receive(:resource).and_return(ActionTracker::NilResource.new)
    @helper = Object.new.extend ActionTracker::Helpers::Render
  end

  it 'track an action' do
    trigger_trackers(['action_test'])

    expect(@fake_session[:action_tracker]).to eq(['Here comes the test'])
  end

  it 'return null if class does not have tracker' do
    trigger_trackers(['some_other_test_action'])

    expect(@fake_session[:action_tracker]).to be_empty
  end

  it 'stacks sequence of trackers' do
    trigger_trackers(%w(action_test another_action_test))

    expect(@fake_session[:action_tracker].size).to eq(2)
    expect(@fake_session[:action_tracker].first).to eq('Here comes the test')
    expect(@fake_session[:action_tracker].last).to eq(action: 'Here comes the object test')
  end

  it 'clear stacks sequence of trackers when the helper is called' do
    trigger_trackers(%w(action_test another_action_test))

    expect(@fake_session[:action_tracker].size).to eq(2)

    allow(@helper).to receive(:session).and_return(@fake_session)
    result = @helper.track_event

    expect(@fake_session[:action_tracker]).to be_nil
    expect(result.size).to eq(2)
    expect(result).to match(['Here comes the test', action: 'Here comes the object test'])
  end

  context 'when the resource does not exists' do
    before do
      allow_any_instance_of(described_class).to receive(:find_resource).and_return('nil_current_resource')
    end

    it 'track events normally' do
      trigger_trackers(%w(action_test))
      expect(@fake_session[:action_tracker]).to match(['Here comes the test'])
    end
  end

  def trigger_trackers(event_list)
    event_list.size.times do |n|
      @event_list[n] = ApplicationTestController.new { include ActionTracker::Concerns::Tracker }
      allow(@event_list[n]).to receive(:action_name).and_return(event_list[n])
      @event_list[n].instance_eval { track_event }
    end
  end
end
