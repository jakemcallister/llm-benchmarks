import type { Route } from "./+types/benchmarks.keyword-delegation-proxy";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/benchmark-page-layout'
import { BenchmarkPageHeader } from '../components/benchmark-page-header'
import { TopPerformerSection } from '../components/top-performer-section';
import { DataTable } from '../components/data-table'
import { CallToActionSection } from '../components/call-to-action-section'
import { Separator } from '../components/ui/separator';
import { Workflow } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Keyword Delegation Proxy Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the keyword delegation and callback semantics benchmark" },
  ];
}

export async function loader({ request }: Route.LoaderArgs) {
  const data = await loadBenchmarkData('keyword_delegation_proxy', request);
  if (!data) {
    throw new Error('Failed to load keyword delegation proxy benchmark data');
  }

  const rankings = getBenchmarkRankings(data);
  const stats = calculateBenchmarkStats(data);

  return {
    data,
    rankings,
    stats,
    topModels: rankings.slice(0, 3),
  };
}

export default function KeywordDelegationProxyBenchmark({ loaderData }: Route.ComponentProps) {
  const { rankings, stats, topModels } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Workflow className="h-8 w-8" />}
          title="Keyword Delegation Proxy"
          stats={stats}
        />
      }
    >
      <BenchmarkPageContent>
        <section className="mb-12">
          <DataTable
            data={rankings}
            title="Keyword Delegation Proxy Benchmark - Individual Model Results"
          />
        </section>

        <Separator className="my-12" />

        <TopPerformerSection
          topModels={topModels}
          championTitle="Keyword Delegation Champions"
        />

        <Separator className="my-12" />

        <CallToActionSection />
      </BenchmarkPageContent>
    </BenchmarkPageLayout>
  );
}
