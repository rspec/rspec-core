## rspec-mocks release history (incomplete)

### 2.0.0.beta.21 (not yet released)

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.0.0.beta.20...v2.0.0.beta.21)

* Bug fixes
  * fixed regression that broke obj.stub_chain(:a, :b => :c)
  * fixed regression that broke obj.stub_chain(:a, :b) { :c }

