package mongo

import (
	"context"
	"golang-web-core/util"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/readpref"
)

type Mongo struct {
	Config
	LogTransactions bool
}

func NewMongoAdapter(config Config, logTransactions bool) *Mongo {
	return &Mongo{
		Config:          config,
		LogTransactions: logTransactions,
	}
}

func (m Mongo) TestConnection() error {
	client, context, cancel, err := m.Connect()
	if err != nil {
		return err
	}
	defer m.Close(client, context, cancel)
	return m.Ping(client, context)
}

func (m Mongo) Close(client *mongo.Client, ctx context.Context, cancel context.CancelFunc) {
	defer cancel()

	defer func() {
		if err := client.Disconnect(ctx); err != nil {
			util.LogFatal(err)
		}
	}()
}

func (m Mongo) Connect() (*mongo.Client, context.Context, context.CancelFunc, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	client, err := mongo.Connect(options.Client().ApplyURI(m.ConnectionString()))
	return client, ctx, cancel, err
}

func (m Mongo) Ping(client *mongo.Client, ctx context.Context) error {
	if err := client.Ping(ctx, readpref.Primary()); err != nil {
		return err
	}
	return nil
}

func (m Mongo) InsertOne(client *mongo.Client, ctx context.Context, col string, doc any) (*mongo.InsertOneResult, error) {
	collection := client.Database(m.Database).Collection(col)
	res, err := collection.InsertOne(ctx, doc)
	if m.LogTransactions {
		util.LogColor("lightgreen", "Inserted one document into collection %v", col)
	}
	return res, err
}

func (m Mongo) InsertMany(client *mongo.Client, ctx context.Context, col string, docs []any) error {
	collection := client.Database(m.Database).Collection(col)
	res, err := collection.InsertMany(ctx, docs)
	if m.LogTransactions {
		util.LogColor("lightgreen", "Inserted %v documents into collection %v", len(res.InsertedIDs), col)
	}
	return err
}

func (m Mongo) Query(client *mongo.Client, ctx context.Context, col string, query, field any) (*mongo.Cursor, error) {
	collection := client.Database(m.Database).Collection(col)
	result, err := collection.Find(ctx, query, options.Find().SetProjection(field))
	if m.LogTransactions && result != nil {
		util.LogColor("lightblue", "Queried %v documents from collection %v", result.RemainingBatchLength(), col)
	}
	return result, err
}

func (m Mongo) UpdateOne(client *mongo.Client, ctx context.Context, col string, filter, update any) error {
	collection := client.Database(m.Database).Collection(col)
	_, err := collection.UpdateOne(ctx, filter, update)
	if m.LogTransactions {
		util.LogColor("lightyellow", "Updated one document in collection %v", col)
	}
	return err
}

func (m Mongo) UpdateMany(client *mongo.Client, ctx context.Context, col string, filter, update any) error {
	collection := client.Database(m.Database).Collection(col)
	res, err := collection.UpdateMany(ctx, filter, update)
	if m.LogTransactions {
		util.LogColor("lightyellow", "Updated %v documents in collection %v", res.ModifiedCount, col)
	}
	return err
}

func (m Mongo) DeleteOne(client *mongo.Client, ctx context.Context, col string, query any) error {
	collection := client.Database(m.Database).Collection(col)
	_, err := collection.DeleteOne(ctx, query)
	if m.LogTransactions {
		util.LogColor("lightred", "Deleted one document from collection %v", col)
	}
	return err
}

func (m Mongo) DeleteMany(client *mongo.Client, ctx context.Context, col string, query any) error {
	collection := client.Database(m.Database).Collection(col)
	res, err := collection.DeleteMany(ctx, query)
	if m.LogTransactions {
		util.LogColor("lightred", "Deleted %v documents from collection %v", res.DeletedCount, col)
	}
	return err
}
