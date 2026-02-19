import { Link, useLocation } from "react-router"
import { Github, Menu, X } from "lucide-react"
import { useState } from "react"
import { ThemeToggle } from "./theme-toggle"
import { Button } from "./ui/button"
import { Logo } from "./logo"
import { BENCHMARK_PATHS, BENCHMARK_TYPES, type BenchmarkType } from "../types/benchmark"

export const Header = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const location = useLocation()
  const benchmarkNavLabels: Record<BenchmarkType, string> = {
    calendar: "Calendar",
    parking_garage: "Parking Garage",
    school_library: "School Library",
    vending_machine: "Vending Machine",
    keyword_delegation_proxy: "Keyword Proxy"
  }

  const toggleMobileMenu = () => setIsMobileMenuOpen(!isMobileMenuOpen)

  const isActive = (path: string) => {
    if (path === "/") {
      return location.pathname === "/"
    }
    return location.pathname.startsWith(path)
  }

  const getLinkClassName = (path: string) => {
    const baseClasses = "transition-colors hover:text-foreground/80 relative"
    const activeClasses = "text-foreground font-semibold after:absolute after:bottom-[-1px] after:left-0 after:right-0 after:h-0.5 after:bg-primary after:rounded-full"
    const inactiveClasses = "text-foreground/60"

    return `${baseClasses} ${isActive(path) ? activeClasses : inactiveClasses}`
  }

  return (
    <header className="sticky top-0 z-50 w-full border-b-2 border-border bg-background shadow-lg">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        <div className="flex items-center">
          <Link to="/" className="transition-opacity hover:opacity-80">
            <Logo size="md" />
          </Link>
        </div>

        <nav className="hidden md:flex items-center space-x-6 text-sm font-medium">
          <Link
            to="/"
            className={getLinkClassName("/")}
          >
            Overall Rankings
          </Link>
          {BENCHMARK_TYPES.map((benchmarkType) => (
            <Link
              key={benchmarkType}
              to={BENCHMARK_PATHS[benchmarkType]}
              className={getLinkClassName(BENCHMARK_PATHS[benchmarkType])}
            >
              {benchmarkNavLabels[benchmarkType]}
            </Link>
          ))}
        </nav>

        <div className="flex items-center space-x-2">
          <Button variant="ghost" size="icon" asChild>
            <a
              href="https://github.com/OskarsEzerins/llm-benchmarks"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="View source on GitHub"
            >
              <Github className="h-4 w-4" />
            </a>
          </Button>
          <ThemeToggle />

          {/* Mobile menu toggle */}
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={toggleMobileMenu}
            aria-label="Toggle mobile menu"
          >
            {isMobileMenuOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
          </Button>
        </div>
      </div>

      {/* Mobile menu */}
      {isMobileMenuOpen && (
        <div className="md:hidden border-t-2 border-border bg-background shadow-lg">
          <nav className="container mx-auto px-4 py-4 space-y-2">
            <Link
              to="/"
              className={`block py-2 px-3 text-sm font-medium transition-colors hover:text-foreground/80 relative ${isActive("/") ? "text-foreground font-semibold bg-primary/10 border-l-4 border-primary shadow-md" : "text-foreground/60"}`}
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Overall Rankings
            </Link>
            {BENCHMARK_TYPES.map((benchmarkType) => {
              const path = BENCHMARK_PATHS[benchmarkType]

              return (
                <Link
                  key={benchmarkType}
                  to={path}
                  className={`block py-2 px-3 text-sm font-medium transition-colors hover:text-foreground/80 relative ${isActive(path) ? "text-foreground font-semibold bg-primary/10 border-l-4 border-primary shadow-md" : "text-foreground/60"}`}
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  {benchmarkNavLabels[benchmarkType]}
                </Link>
              )
            })}
          </nav>
        </div>
      )}
    </header>
  )
}
