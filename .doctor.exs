%Doctor.Config{
  exception_moduledoc_required: true,
  failed: false,
  ignore_modules: [
    ~r/^PlaygroundWeb.*$/,
    ~r/^Playground.Release$/
  ],
  ignore_paths: [],
  min_module_doc_coverage: 80,
  min_module_spec_coverage: 50,
  min_overall_doc_coverage: 80,
  min_overall_spec_coverage: 50,
  raise: false,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  umbrella: true
}
