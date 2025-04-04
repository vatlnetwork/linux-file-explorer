#include <gtk/gtk.h>

int main(int argc, char *argv[]) {
  gtk_init(&argc, &argv);

  GtkWidget *window = gtk_window_new();
  gtk_window_set_title(GTK_WINDOW(window), "My Application");
  gtk_window_set_default_size(GTK_WINDOW(window), 1280, 720);
  gtk_window_set_resizable(GTK_WINDOW(window), TRUE);
  
  // Remove window decorations
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  
  gtk_widget_show(GTK_WIDGET(window));

  gtk_main();
  return 0;
} 