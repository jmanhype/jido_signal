# Used by "mix format"
[
  plugins: [Quokka],
  inputs: [".formatter.exs", "{config,lib,test}/**/*.{ex,exs}"],

  # Quokka configuration for automatic code rewriting
  quokka: [
    # Enable automatic sorting for better consistency
    autosort: [:map, :defstruct],

    # File processing control (defaults work fine)
    # files: %{included: [], excluded: []},

    # Apply comprehensive rewrites for high-quality code
    # (leaving :only empty means all rewrites are enabled)
    only: [],

    # Exclude specific rewrites that might interfere with intentional patterns
    exclude: [
      # Don't re-underscore numbers that already have underscores in specific patterns
      :nums_with_underscores,

      # Allow certain functions to avoid pipe conversion when it might reduce readability
      piped_functions: [
        # Ecto-specific functions that are clearer without pipes
        :subquery,
        :fragment,
        # Common test functions
        :assert_raise,
        :assert_receive
      ]
    ]
  ]
]
