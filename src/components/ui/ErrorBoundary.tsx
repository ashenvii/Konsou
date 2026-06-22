import { Component } from "react";
import type { ErrorInfo, ReactNode } from "react";
import { Button } from "./Button";

interface Props {
  children: ReactNode;
  /** Optional label shown in the error UI (e.g. "My List"). */
  name?: string;
}

interface State {
  hasError: boolean;
  message: string | null;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, message: null };

  static getDerivedStateFromError(error: unknown): State {
    return {
      hasError: true,
      message: error instanceof Error ? error.message : null,
    };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error(`[ErrorBoundary${this.props.name ? ` ${this.props.name}` : ""}]`, error, info);
  }

  retry = () => this.setState({ hasError: false, message: null });

  render() {
    if (!this.state.hasError) return this.props.children;

    return (
      <div className="k-errorboundary">
        <p className="k-errorboundary__title">Something went wrong</p>
        {this.state.message && (
          <p className="k-errorboundary__detail">{this.state.message}</p>
        )}
        <Button variant="secondary" onClick={this.retry}>
          Retry
        </Button>
      </div>
    );
  }
}
