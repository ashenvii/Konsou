import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { ErrorBoundary } from "./ErrorBoundary";

/**
 * The boundary is the last thing between a render crash and a white screen, so
 * what it must guarantee is that the user still sees something and still has a
 * way out. Also the smoke test for the component-testing setup itself.
 */

function Boom({ throws, message = "kaboom" }: { throws: boolean; message?: string }) {
  if (throws) throw new Error(message);
  return <p>All fine</p>;
}

beforeEach(() => {
  // React logs the caught error to the console on purpose; silence it so a
  // passing run stays readable.
  vi.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("ErrorBoundary", () => {
  it("stays out of the way when nothing is wrong", () => {
    render(
      <ErrorBoundary>
        <Boom throws={false} />
      </ErrorBoundary>,
    );
    expect(screen.getByText("All fine")).toBeInTheDocument();
    expect(screen.queryByText("Something went wrong")).not.toBeInTheDocument();
  });

  it("shows a message and a way out instead of a blank screen", () => {
    render(
      <ErrorBoundary name="My List">
        <Boom throws message="database is locked" />
      </ErrorBoundary>,
    );
    expect(screen.getByText("Something went wrong")).toBeInTheDocument();
    expect(screen.getByText("database is locked")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /retry/i })).toBeInTheDocument();
  });

  it("renders without a detail line when the throw carried no message", () => {
    render(
      <ErrorBoundary>
        <Boom throws message="" />
      </ErrorBoundary>,
    );
    expect(screen.getByText("Something went wrong")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /retry/i })).toBeInTheDocument();
  });

  it("recovers when retry is pressed and the cause is gone", async () => {
    const user = userEvent.setup();

    function Harness() {
      const [broken, setBroken] = useState(true);
      return (
        <>
          <button onClick={() => setBroken(false)}>Fix it</button>
          <ErrorBoundary>
            <Boom throws={broken} />
          </ErrorBoundary>
        </>
      );
    }

    render(<Harness />);
    expect(screen.getByText("Something went wrong")).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Fix it" }));
    await user.click(screen.getByRole("button", { name: /retry/i }));

    expect(screen.getByText("All fine")).toBeInTheDocument();
    expect(screen.queryByText("Something went wrong")).not.toBeInTheDocument();
  });

  it("names the boundary in the log so a crash report says where it happened", () => {
    render(
      <ErrorBoundary name="My List">
        <Boom throws />
      </ErrorBoundary>,
    );
    const logged = (console.error as unknown as ReturnType<typeof vi.fn>).mock.calls;
    expect(logged.some((args) => String(args[0]).includes("My List"))).toBe(true);
  });
});
