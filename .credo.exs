# .credo.exs
# Configuration for Credo static analysis tool
# Works in tandem with Quokka formatter plugin for comprehensive code quality

%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "test/",
          "config/",
          "mix.exs",
          ".formatter.exs"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: [
        #
        ## Consistency Checks
        #
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.ParameterPatternMatching, []},
        {Credo.Check.Consistency.SpaceAroundOperators, []},
        {Credo.Check.Consistency.SpaceInParentheses, []},
        {Credo.Check.Consistency.TabsOrSpaces, []},

        #
        ## Design Checks
        #
        {Credo.Check.Design.AliasUsage, [priority: :low, if_nested_deeper_than: 2, if_called_more_often_than: 0]},
        {Credo.Check.Design.TagTODO, [priority: :low]},
        {Credo.Check.Design.TagFIXME, []},

        #
        ## Readability Checks
        # These complement Quokka's automatic rewrites
        #
        {Credo.Check.Readability.AliasOrder, []},
        {Credo.Check.Readability.FunctionNames, []},
        {Credo.Check.Readability.LargeNumbers, []},
        {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
        {Credo.Check.Readability.ModuleAttributeNames, []},
        {Credo.Check.Readability.ModuleDoc, []},
        {Credo.Check.Readability.ModuleNames, []},
        {Credo.Check.Readability.ParenthesesInCondition, []},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
        {Credo.Check.Readability.PredicateFunctionNames, []},
        {Credo.Check.Readability.PreferImplicitTry, []},
        {Credo.Check.Readability.RedundantBlankLines, []},
        {Credo.Check.Readability.Semicolons, []},
        {Credo.Check.Readability.SpaceAfterCommas, []},
        {Credo.Check.Readability.StringSigils, []},
        {Credo.Check.Readability.TrailingBlankLine, []},
        {Credo.Check.Readability.TrailingWhiteSpace, []},
        {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
        {Credo.Check.Readability.VariableNames, []},

        #
        ## Refactoring Opportunities (non-fatal - exit_status: 0)
        # These provide feedback without breaking builds
        # Quokka will automatically fix many of these where possible
        #
        {Credo.Check.Refactor.DoubleBooleanNegation, [exit_status: 0]},
        {Credo.Check.Refactor.CondStatements, [exit_status: 0]},
        {Credo.Check.Refactor.CyclomaticComplexity, [exit_status: 0, max_complexity: 10]},
        {Credo.Check.Refactor.FunctionArity, [exit_status: 0, max_arity: 6]},
        {Credo.Check.Refactor.LongQuoteBlocks, [exit_status: 0]},
        {Credo.Check.Refactor.MapInto, [exit_status: 0]},
        {Credo.Check.Refactor.MatchInCondition, [exit_status: 0]},
        {Credo.Check.Refactor.NegatedConditionsInUnless, [exit_status: 0]},
        {Credo.Check.Refactor.NegatedConditionsWithElse, [exit_status: 0]},
        {Credo.Check.Refactor.Nesting, [exit_status: 0, max_nesting: 3]},
        {Credo.Check.Refactor.UnlessWithElse, [exit_status: 0]},
        {Credo.Check.Refactor.WithClauses, [exit_status: 0]},
        
        # Additional refactor checks that work well with Quokka
        {Credo.Check.Refactor.PipeChainStart, [exit_status: 0]},
        {Credo.Check.Refactor.RedundantWithClauseResult, [exit_status: 0]},

        #
        ## Warnings
        #
        {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
        {Credo.Check.Warning.BoolOperationOnSameValues, []},
        {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
        {Credo.Check.Warning.IExPry, []},
        {Credo.Check.Warning.IoInspect, []},
        {Credo.Check.Warning.LazyLogging, []},
        {Credo.Check.Warning.MixEnv, []},
        {Credo.Check.Warning.OperationOnSameValues, []},
        {Credo.Check.Warning.OperationWithConstantResult, []},
        {Credo.Check.Warning.RaiseInsideRescue, []},
        {Credo.Check.Warning.UnusedEnumOperation, []},
        {Credo.Check.Warning.UnusedFileOperation, []},
        {Credo.Check.Warning.UnusedKeywordOperation, []},
        {Credo.Check.Warning.UnusedListOperation, []},
        {Credo.Check.Warning.UnusedPathOperation, []},
        {Credo.Check.Warning.UnusedRegexOperation, []},
        {Credo.Check.Warning.UnusedStringOperation, []},
        {Credo.Check.Warning.UnusedTupleOperation, []},
        {Credo.Check.Warning.UnsafeExec, []}
      ]
    }
  ]
}
