import QtQuick
import QtTest
import "../AIUsageParser.js" as Parser

TestCase {
    name: "AIUsageParser"

    function test_successfulReport() {
        const resetAt = new Date(Date.now() + 1800 * 1000).toISOString();
        const output = JSON.stringify({
            schema_version: 1,
            primary: "openai@work",
            entries: [
                {
                    id: "openai@work",
                    name: "OpenAI · work",
                    display_name: "OpenAI · work",
                    plan: "Plus",
                    status: "ready",
                    fetched_at: new Date().toISOString(),
                    metrics: [
                        {
                            label: "Session",
                            percent: 42,
                            value: "42%",
                            detail: "Resets soon",
                            severity: "low",
                            reset_at: resetAt,
                            window_secs: 3600
                        }
                    ],
                    sections: [
                        {
                            type: "metric",
                            label: "Session",
                            percent: 42,
                            value: "42%",
                            detail: "Resets soon",
                            severity: "low",
                            reset_at: resetAt
                        },
                        {
                            type: "text",
                            label: "Credits",
                            value: "$4.00"
                        },
                        {
                            type: "block",
                            label: "Usage",
                            body: ["Today: $1.00"]
                        },
                        {
                            type: "spacer"
                        }
                    ]
                },
                {
                    id: "openai@personal",
                    display_name: "OpenAI · personal",
                    status: "ready",
                    metrics: [
                        {
                            label: "Monthly",
                            percent: 18,
                            value: "18%",
                            reset_at: resetAt
                        }
                    ],
                    sections: [
                        {
                            type: "metric",
                            label: "Monthly",
                            percent: 18,
                            value: "18%",
                            reset_at: resetAt
                        }
                    ]
                }
            ]
        });
        const result = Parser.parseProcessResult(0, output, false);

        verify(result.ok);
        compare(result.report.entries.length, 2);
        compare(result.report.primary, "openai@work");
        compare(result.report.entries[0].id, "openai@work");
        compare(result.report.entries[1].id, "openai@personal");
        compare(result.report.entries[0].plan, "Plus");
        compare(result.report.entries[0].sections.length, 4);
        compare(result.report.entries[0].sections[0].metric.percent, 42);
        verify(result.report.entries[0].sections[0].metric.elapsedPercent > 45);
        verify(result.report.entries[0].sections[0].metric.elapsedPercent < 55);
        compare(result.report.entries[0].sections[1].value, "$4.00");
        compare(result.report.entries[1].metrics[0].elapsedPercent, null);
    }

    function test_emptyReportAndEmptyOutput() {
        const emptyReport = Parser.parseProcessResult(0, '{"entries":[]}', false);
        const emptyOutput = Parser.parseProcessResult(0, "", false);

        verify(emptyReport.ok);
        compare(emptyReport.report.entries.length, 0);
        verify(!emptyOutput.ok);
        compare(emptyOutput.message, "AI Usage returned no report.");
    }

    function test_malformedOutput() {
        const malformed = Parser.parseProcessResult(0, "{not-json", false);
        const invalidShape = Parser.parseProcessResult(0, '{"vendors":[]}', false);

        verify(!malformed.ok);
        compare(malformed.message, "AI Usage returned invalid JSON.");
        verify(!invalidShape.ok);
        compare(invalidShape.message, "AI Usage returned an invalid report.");
    }

    function test_timeoutPreservesPreviousReportAsStale() {
        const previousEntries = [
            {
                id: "openai",
                metrics: [
                    {
                        percent: 25
                    }
                ]
            }
        ];
        const timeout = Parser.parseProcessResult(124, "", true);
        const next = Parser.applyResult(previousEntries, true, timeout);

        verify(!timeout.ok);
        compare(timeout.message, "AI Usage refresh timed out.");
        verify(next.entries === previousEntries);
        verify(next.hasReport);
        verify(next.stale);
    }

    function test_providerErrorDoesNotExposeCachedGauges() {
        const output = JSON.stringify({
            entries: [
                {
                    id: "anthropic@work",
                    display_name: "Claude · work",
                    status: "error",
                    error: "Credentials need login",
                    metrics: [
                        {
                            label: "Session",
                            percent: 87,
                            value: "87%",
                            detail: "Cached"
                        }
                    ],
                    sections: [
                        {
                            type: "metric",
                            label: "Session",
                            percent: 87,
                            value: "87%"
                        }
                    ]
                }
            ]
        });
        const result = Parser.parseProcessResult(1, output, false);

        verify(result.ok);
        compare(result.report.entries.length, 1);
        compare(result.report.entries[0].id, "anthropic@work");
        verify(result.report.entries[0].failed);
        compare(result.report.entries[0].metrics.length, 0);
        compare(result.report.entries[0].sections.length, 0);
        compare(result.report.entries[0].error, "Credentials need login");
    }

    function test_unavailableProvidersAreHiddenFromPopupEntries() {
        const output = JSON.stringify({
            primary: "claude",
            entries: [
                {
                    id: "claude",
                    display_name: "Claude",
                    status: "error",
                    error: "Unavailable"
                },
                {
                    id: "codex",
                    display_name: "Codex",
                    status: "ready",
                    metrics: []
                }
            ]
        });
        const result = Parser.parseReport(output);

        verify(result.ok);
        compare(result.report.entries.length, 2);
        const visibleEntries = Parser.availableEntries(result.report.entries);
        compare(visibleEntries.length, 1);
        compare(visibleEntries[0].id, "codex");
    }

    function test_textSanitization() {
        const output = JSON.stringify({
            entries: [
                {
                    id: "openai",
                    status: "error",
                    error: "\u001b[31mNeeds login\u001b[0m\u202e"
                }
            ]
        });
        const result = Parser.parseReport(output);

        verify(result.ok);
        compare(result.report.entries[0].error, "Needs login");
    }
}
