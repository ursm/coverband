# frozen_string_literal: true

require File.expand_path('../../test_helper', File.dirname(__FILE__))

class ReportHTMLTest < Minitest::Test
  def setup
    super
    @redis = Redis.new
    @store = Coverband::Adapters::RedisStore.new(@redis)
    @store.clear!
    Coverband.configure do |config|
      config.reporter          = 'scov'
      config.store             = @store
      config.s3_bucket         = nil
      config.ignore            = ['notsomething.rb']
    end
    mock_file_hash
  end

  test 'generate dynamic content hosted html report' do
    @store.send(:save_report, basic_coverage)

    html = Coverband::Reporters::HTMLReport.new(@store,
                                                html: true,
                                                open_report: false).report
    assert_match 'Generated by', html
  end

  test 'generate static HTML report file' do
    @store.send(:save_report, basic_coverage)

    reporter = Coverband::Reporters::HTMLReport.new(@store,
                                                    html: false,
                                                    open_report: false)
    Coverband::Utils::HTMLFormatter.any_instance.expects(:format!).once
    reporter.report
  end

  test 'generate dynamic content detailed file report' do
    @store.send(:save_report, basic_coverage_full_path)

    filename = basic_coverage_file_full_path
    base_path = '/coverage'
    html = Coverband::Reporters::HTMLReport.new(Coverband.configuration.store,
      filename: filename,
      base_path: base_path,
      open_report: false).file_details
    assert_match 'Coverage first seen', html
  end

  test 'generate dynamic content detailed file report handles missing file' do
    @store.send(:save_report, basic_coverage_full_path)

    filename = 'missing_path'
    base_path = '/coverage'
    html = Coverband::Reporters::HTMLReport.new(Coverband.configuration.store,
      filename: filename,
      base_path: base_path,
      open_report: false).file_details
    assert_match 'File No Longer Available', html
  end

  test 'generate dynamic content detailed file report does not allow loading real non project files' do
    @store.send(:save_report, basic_coverage_full_path)

    filename = "#{test_root}/test_helper.rb"
    base_path = '/coverage'
    html = Coverband::Reporters::HTMLReport.new(Coverband.configuration.store,
      filename: filename,
      base_path: base_path,
      open_report: false).file_details
    assert_match 'File No Longer Available', html
  end
end
