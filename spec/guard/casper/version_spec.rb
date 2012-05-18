require 'scenario_helper'

describe Guard::CasperVersion do
  describe 'VERSION' do
    it 'defines the version' do
      Guard::CasperVersion::VERSION.should match /\d+.\d+.\d+/
    end
  end
end
