class EvalHelpersTest < Test::Unit::TestCase

  def setup
    @environment = Moonrope::EvalEnvironment.new(Moonrope::Base.new, FakeRequest.new(:params => {'page' => 1}))
    @environment.reset
  end

  def test_errors
    assert_raises Moonrope::Errors::NotFound do
      @environment.error(:not_found, "Page not found")
    end

    assert_raises Moonrope::Errors::AccessDenied do
      @environment.error(:access_denied, "User not authenticated")
    end

    assert_raises Moonrope::Errors::ValidationError do
      @environment.error(:validation_error, [{:field => 'user', :message => 'should not be blank'}])
    end

    assert_raises Moonrope::Errors::ParameterError do
      @environment.error(:parameter_error, [{:field => 'page', :message => 'should be present'}])
    end

    assert_raises Moonrope::Errors::RequestError do
      @environment.error(:misc_error, "Unknown issue")
    end
  end

  def test_paginate
    items = PaginationCollection.new
    result = @environment.paginate(items)  { |r| r }
    assert result.is_a?(Array)
    assert @environment.flags[:paginated].is_a?(Hash)
  end

  class PaginationCollection
    def to_a
      [1,2,3,4,5,6]
    end

    def page(page)
      self
    end

    def per(max_per_page)
      self
    end

    def total_pages
      2
    end

    def total_count
      34
    end
  end


end
