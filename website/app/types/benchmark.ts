export interface BenchmarkResult {
  implementation: string;
  timestamp: string;
  metrics: {
    rubocop_offenses: number;
    tests_passed: number;
    total_tests: number;
    success_rate: number;
    primary_metric: number;
    success: boolean;
  };
}

export interface BenchmarkAggregate {
  run_count: number;
  metrics: {
    rubocop_offenses: number;
    tests_passed: number;
    total_tests: number;
    success_rate: number;
    primary_metric: number;
    success: number;
  };
  rubocop_offenses: number;
  score: number;
  score_breakdown: {
    success_score: number;
    quality_score: number;
  };
}

export interface BenchmarkData {
  results: BenchmarkResult[];
  aggregates: Record<string, BenchmarkAggregate>;
}

export interface ModelRanking {
  implementation: string;
  score: number;
  success_rate: number;
  quality_score: number;
  tests_passed: number;
  total_tests: number;
  rubocop_offenses: number;
  completed_benchmarks: number;
  total_benchmarks: number;
  date: Date;
}

export const BENCHMARK_TYPES = [
  'calendar',
  'parking_garage',
  'school_library',
  'vending_machine',
  'keyword_delegation_proxy'
] as const;

export type BenchmarkType = (typeof BENCHMARK_TYPES)[number];

export const BENCHMARK_NAMES: Record<BenchmarkType, string> = {
  calendar: 'Calendar System',
  parking_garage: 'Parking Garage',
  school_library: 'School Library',
  vending_machine: 'Vending Machine',
  keyword_delegation_proxy: 'Keyword Delegation Proxy'
};

export const BENCHMARK_PATHS: Record<BenchmarkType, string> = {
  calendar: '/benchmarks/calendar',
  parking_garage: '/benchmarks/parking-garage',
  school_library: '/benchmarks/school-library',
  vending_machine: '/benchmarks/vending-machine',
  keyword_delegation_proxy: '/benchmarks/keyword-delegation-proxy'
};
