// Package trace provides utilities for initializing OpenTelemetry tracing.
package trace

import (
	"context"
	"errors"
	"fmt"
	"log"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
)

// InitGlobalTraceProvider initializes and sets a global trace provider for OpenTelemetry.
func InitGlobalTraceProvider(ctx context.Context) (func(context.Context) error, error) {
	exporter, err := otlptracegrpc.New(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed initializing global trace provider: %w", err)
	}

	res, err := resource.New(ctx, resource.WithFromEnv(), resource.WithHost())
	if errors.Is(err, resource.ErrPartialResource) ||
		errors.Is(err, resource.ErrSchemaURLConflict) {
		log.Println(err) // Log non-fatal issues.
	} else if err != nil {
		return nil, fmt.Errorf("failed initializing global trace provider: %w", err)
	}

	traceprovider := trace.NewTracerProvider(
		trace.WithBatcher(exporter),
		trace.WithResource(res),
	)

	// set the global tracer provider
	otel.SetTracerProvider(traceprovider)
	// set the global propagator to use TraceContext and Baggage
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	return traceprovider.Shutdown, nil
}
